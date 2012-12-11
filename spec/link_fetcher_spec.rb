require './lib/link_alert/link_fetcher'


describe LinkAlert::LinkFetcher do

  describe '#process_links' do
    before do
      @fetcher = LinkAlert::LinkFetcher.new(nil)
    end

    it "should exclude search engine referrers" do
      raw = [{domain: 'google', path: '(not set)'}]
      @fetcher.process_links(raw).should == []
    end

    it "should exclude direct traffic" do
      raw = [{domain: '(direct)', path: '(not set)'}]
      @fetcher.process_links(raw).should == []
    end

    it "should combine domain and path" do
      raw = [
        {domain: 'site.com', path: '/blog/2012/01'},
        {domain: 'another.com', path: '/page.html'},
      ]
      @fetcher.process_links(raw).should == [
        'site.com/blog/2012/01',
        'another.com/page.html'
      ]
    end
  end
end
