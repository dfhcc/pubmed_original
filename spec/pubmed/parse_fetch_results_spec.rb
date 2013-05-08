require 'spec_helper'

module TestModule
  extend Pubmed::ParseFetchResults
end

describe Pubmed::ParseFetchResults do

  describe '#parse_medline_cite' do
    before(:each) do
      @pubmed_article = Nokogiri::XML(File.open(File.expand_path('spec/fixtures/efetch_rettype_medline.xml'))).xpath("//PubmedArticle[1]").first
      @expected = {:pubmed_id => '23645694', :date_published => '2013-5-6'}
    end

    it 'should return a hash containing the pubmed_id and date_published' do
      TestModule.parse_medline_cite(@pubmed_article.to_xml).should == @expected
    end
  end
end