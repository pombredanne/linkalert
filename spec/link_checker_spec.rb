require './lib/link_alert/link_checker'


describe LinkAlert::LinkChecker do

  describe "#hash_url" do
    before do 
      @url = 'example.com/page.html'
    end

    it "should hash URLs for the same profile consistently" do
      checker_one = LinkAlert::LinkChecker.new(nil, '123456')
      checker_two = LinkAlert::LinkChecker.new(nil, '123456')

      result_one = checker_one.hash_url(@url)
      result_two = checker_two.hash_url(@url)

      result_one.should == result_two
    end

    it "should hash the same URL for another profile differently" do
      checker_one = LinkAlert::LinkChecker.new(nil, '123456')
      checker_two = LinkAlert::LinkChecker.new(nil, '654321')

      result_one = checker_one.hash_url(@url)
      result_two = checker_two.hash_url(@url)

      result_one.should_not == result_two
    end
  end

  describe "#determine_new_links" do
    before do
      @checker = LinkAlert::LinkChecker.new(nil, '123456')
      @checker.stub(:url_exists?) { false }

      @urls = [
        'example1.com/page.html',
        'example2.com/blog',
        'example3.com/'
      ]
    end

    it "should return an array of new links" do
      @checker.determine_new_links(@urls).should == @urls
    end

    it "should discard any links already in the database" do
      @checker.stub(:url_exists?).with(@urls[0]) { true }
      @checker.determine_new_links(@urls).should == @urls[1..-1]
    end
  end
end
