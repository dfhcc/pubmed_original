module Pubmed
  module Client

    def self.find_by_full_author_name(member, options={})
      query = "#{member.last_first_and_middle_initial_name}[FAU]"
      Pubmed::API.search_and_fetch(query, options)
    end

    def self.find_by_last_name_and_first_name(member, options={})
      query = "#{member.last_name} #{member.first_name}[FAU]"
      Pubmed::API.search_and_fetch(query, options)
    end

    def self.find_by_pubmed_alias(member, options={})
      query = if member.publication_alias.present?
                '(' + member.publication_alias.split(', ').map { |pa| "#{pa.strip}[AU]" }.join(' OR ') + ')'
              else
                ''
              end
      Pubmed::API.search_and_fetch(query, options)
    end

    def self.find_first_by_pubmed_id(pubmed_id)
      result = Pubmed::API.fetch(pubmed_id)
      if result.count > 0
        result.publications.first
      end
    end

    def self.search_by_full_name_and_reporting_year(name, reporting_year)
      options = { 'retmax' => '1000', 'mindate' => format_date(reporting_year.start_of_year), 'maxdate' => format_date(reporting_year.end_of_year) }
      Pubmed::API.search(name, options)
    end

    # Do a search built from options and return the first 10 results (by default).
    #
    # These results are 'paginated' by specifying an offset (default 0)
    #
    # options:
    #   :author  - author name
    #   :author_search_type - ex: [fau]
    #   :title - publication title
    #   :pubmed_ids - search within these pubmed IDs
    #   :start_date - search for pubs published after this date (yyyy/mm/dd)
    #   :end_date - but before this date (yyyy/mm/dd)
    #
    #   :results - number of results to return (default 10)
    #   :offset  - which 'page' of results you want (default 0)
    def self.paginated_search(options={})
      options[:results] ||= 10
      options[:offset]  ||= 0
      return nil unless options[:author] && options[:title] && options[:pubmed_ids]     

      query         = generate_query(options)
      query_options = generate_options(options[:start_date], options[:end_date], options[:results], options[:offset])

      Pubmed::API.search_and_fetch(query, query_options)
    end
    
  private

    # Generate a query in the form pubmed wants it.  Looks like:
    # "author name[author search type] AND (words[ti] AND from[ti] AND title[ti])
    def self.generate_query(options)
      author_clause = generate_author_clause(options[:author], options[:author_search_type])
      title_clause  = generate_title_clause(options[:title], author_clause)
      pmid_clause   = generate_pmid_clause(options[:pubmed_ids], (author_clause + title_clause).present?)
      author_clause + title_clause + pmid_clause
    end

    def self.generate_title_clause(title, author_clause)
      ''.tap do |title_clause|
        if title.present?
          title_clause << " AND " unless author_clause.blank?
          title_clause << '('
          title_clause << title.split(' ').map { |word| "#{word}[ti]" }.join(' AND ')
          title_clause << ')'
        end
      end
    end

    def self.generate_author_clause(author, author_search_type)
      author.blank? ? '' : "#{author}[#{author_search_type}]"
    end

    def self.generate_pmid_clause(pubmed_ids, has_author_or_title_clause)
      return '' if pubmed_ids.blank?
      # 'dynamic' delimitation: create array by splitting on 1st non-number character and then ignore any non-number array items
      pmid_ary = pubmed_ids.split(pubmed_ids.strip.match(/[^0-9]+/).nil? ? ' ' : pubmed_ids.strip.match(/[^0-9]+/)[0])
      [].tap do |pmid_clause|
        pmid_ary.each do |pmid|
          pmid_clause << "#{' OR' if has_author_or_title_clause || !pmid_clause.blank? } #{pmid.strip}[uid]" if pmid.strip.match(/[^0-9]/).nil?  
        end
      end.join('')
    end

    def self.generate_options(start_date, end_date, results=10, offset=0)
      {'datetype' => 'pdat'}.tap do |options|
        # retmax can't be more than 100 or less than 1
        results = results.to_i
        options['retmax'] = results > 100 ? 100 : (results < 1 ? 10 : results)
        # retstart defaults to zero and can't be less than zero
        offset = offset.to_i
        options['retstart'] = offset < 0 ? 0 : offset             
        # add formatted dates to options; add today's date to maxdate if mindate present but maxdate is not      
        mindate = format_date(start_date)
        maxdate = format_date(end_date)
        maxdate = format_date(Date.today) if maxdate.blank? && !mindate.blank?
        options['mindate'] = mindate unless mindate.blank?
        options['maxdate'] = maxdate unless  maxdate.blank?
      end
    end

    def self.format_date(raw_date)
      valid_date?(raw_date) ? raw_date.to_date.strftime('%Y/%m/%d') : ''
    end
    
    def self.valid_date?(date)
      date.to_s.to_date
      true
    rescue
      false
    end
      
  end
end