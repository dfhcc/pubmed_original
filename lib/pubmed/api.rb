module Pubmed
  SearchResult = Struct.new(:count, :pubmed_ids)

  class FetchResult

    attr_reader :publications
    attr_reader :total_count

    def initialize(publications)
      @publications = publications
    end

    def total_count=(total_count)
      @total_count = total_count.to_i
    end

    def count
      @count ||= @publications.size
    end

  end

  module API

    require 'nokogiri'

    extend ParseFetchResults
    extend Retryable

    BASE_URI = 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/'
    ESEARCH_URI = BASE_URI + 'esearch.fcgi'
    EFETCH_URI  = BASE_URI + 'efetch.fcgi'

    SLEEP_TIME_BETWEEN_REQUESTS = 1.0
    MAX_RETRY_ATTEMPTS = 3
    
    def self.search(query, options)
      return SearchResult.new(0, []) if query.blank?
      retryable(:on => OpenURI::HTTPError, :tries => MAX_RETRY_ATTEMPTS, :sleep => SLEEP_TIME_BETWEEN_REQUESTS) do
        search_uri = generate_search_uri(query, options)
        parse_search_results(get(search_uri))
      end
    end
    
    def self.fetch(pubmed_ids)
      retryable(:tries => MAX_RETRY_ATTEMPTS, :sleep => SLEEP_TIME_BETWEEN_REQUESTS) do
        return FetchResult.new([]) if pubmed_ids.blank?
        fetch_uri = generate_fetch_uri(pubmed_ids)
        publications = parse_fetch_results(get(fetch_uri))
        FetchResult.new(publications)
      end
    end  

    # Search pubmed with query (and options, optionally), then fetch the articles found in the search and 
    # return them.
    def self.search_and_fetch(query, options={})
      search_results = search(query, options)
      fetch_results = fetch(search_results.pubmed_ids)
      fetch_results.total_count = search_results.count
      fetch_results
    end
      
  private

    def self.get(uri)
      open(uri).read
    end

    def self.generate_search_uri(query, options)
      search_querystring = querystringify(options.merge('term' => query, 'tool' => 'dfhcc_informatics'))      
      ESEARCH_URI + "?" + search_querystring
    end

    def self.generate_fetch_uri(pubmed_ids)
      fetch_query_hash = {'id' => [pubmed_ids].flatten.join(','), 'rettype' => 'medline', 'retmode' => 'xml', 'db' => 'pubmed', 'tool' => 'dfhcc_informatics'}
      fetch_querystring = querystringify(fetch_query_hash)
      EFETCH_URI + "?#{fetch_querystring}"
    end
    
    def self.querystringify(hash)
      hash.map do |opt| 
        URI.escape(opt.join('='))
      end.join('&')
    end
    
    # Returns a SearchResult struct
    def self.parse_search_results(xml_string)
      doc = Nokogiri.parse(xml_string)
      raise unless doc.xml?
      count = doc.root.xpath('Count')[0].content
      pubmed_ids = doc.xpath('//Id').map(&:content)
      SearchResult.new(count, pubmed_ids)
    rescue
      SearchResult.new(0, [])
    end
    
  end
end