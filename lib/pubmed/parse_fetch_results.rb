module Pubmed
  module ParseFetchResults

    # Accepts an xml_string of pubmed fetch results representing several articles.  Returns an array of hashes
    # that describe publications.
    def parse_fetch_results(xml)
      hash_of_pubmed_articles = Hash.from_xml(xml)

      array_of_articles = hash_of_pubmed_articles['PubmedArticleSet']['PubmedArticle'] || []

      # If we received an XML document for a single pubmed ID, we'll have a hash instead of an array; if we put the hash into an array,
      # we can use the following inject statement.
      if array_of_articles.instance_of?(Hash)
        array_of_articles = [array_of_articles] 
      end

      array_of_articles.inject([]) do |publications, pubmed_article_hash|
        publications << parse_pubmed_article(pubmed_article_hash)
      end
    end

    # Parse a single pubmed article record.  Returns a hash with publication and journal attributes. 
    def parse_pubmed_article(pubmed_article)
      Hash[:publication => {}, :journal => {}].tap do |pub_hash|
        medline_cite = pubmed_article['MedlineCitation']

        if medline_cite
          pub_hash[:publication].merge!(parse_medline_cite(medline_cite))
          pub_hash[:publication][:pmc_id] = pubmed_article['PubmedData']['ArticleIdList']['ArticleId'].detect { |e| e =~ /PMC/ }
          article = medline_cite['Article']
        end

        if article 
          pub_hash[:publication].merge!(parse_article(article)) 
          journal = article['Journal']
        end

        if journal
          pub_hash[:journal].merge!(parse_journal(journal))
          journal_issue = journal['JournalIssue']
        end

        if journal_issue
          pub_hash[:publication].merge!(parse_journal_issue(journal_issue))
        end
      end
    end

    def parse_medline_cite(medline_cite)
      Hash.new.tap do |hsh|
        hsh[:pubmed_id]      = medline_cite['PMID']
        hsh[:date_published] = [ medline_cite['DateCreated']['Year'], medline_cite['DateCreated']['Month'], 
                                medline_cite['DateCreated']['Day'] ].compact.join('-')
      end
    end

    def parse_article(article)
      Hash.new.tap do |hsh|
        hsh[:title] = article['ArticleTitle']
        hsh[:authors] = parse_authors(article['AuthorList']['Author']) { |author| "#{author['LastName']} #{author['Initials']}" }
        hsh[:full_author_names] = parse_authors(article['AuthorList']['Author']) { |author| "#{author['LastName']} #{author['ForeName']}" }
        hsh[:abstract] = article['Abstract'] && article['Abstract']['AbstractText']
        hsh[:pages] = article['Pagination'] && article['Pagination']['MedlinePgn']
        hsh[:review_article] = article_is_review?(article)
      end
    end

    def article_is_review?(article)
      publication_types = article['PublicationTypeList'] && article['PublicationTypeList']['PublicationType']
      publication_types.present? && publication_types.any? { |publication_type| publication_type == 'Review' } # I want a false value, not a nil value
    end

    # The authors parameter can be an array (when there are multiple authors) or simply
    # a hash with LastName and FirstName keys (where there is a single author).
    # Either way, we turn it into an array, and yield the individual author hashes to a block; each resulting string
    # is 'map'ped and joined.
    def parse_authors(authors)
      authors_array = [authors].flatten
      authors_array.map do |author|
        yield author
      end.join(', ')
    end

    def parse_journal(journal)
      Hash.new.tap do |hsh|
        hsh[:name] = journal['Title'].split(' = ').first.titleize
        hsh[:abbreviation] = journal['ISOAbbreviation']
      end
    end

    def parse_journal_issue(journal_issue)
      year = journal_issue['PubDate']['Year']
      month = journal_issue['PubDate']['Month']
      day = journal_issue['PubDate']['Day']

      Hash.new.tap do |hsh|
        hsh[:issue_date] = [year, month, day].compact.join(' ') 
        hsh[:volume] = journal_issue['Volume']
        hsh[:issue] = journal_issue['Issue']
      end
    end

  end
end