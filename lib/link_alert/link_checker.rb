require 'digest/sha1'


module LinkAlert

  class LinkChecker

    # The name of the MongoDB collection where link data is held.
    LINKS_COLLECTION_NAME = 'links'

    # Initialize a new LinkChecker.
    # 
    # db - Mongo::Database instance.
    # profile_id - String Analytics profile ID.
    # 
    # Returns a new LinkChecker instance.
    def initialize(db, profile_id)
      @db = db
      @profile_id = profile_id
    end

    # Filter an array to return only unseen links.
    # 
    # all_urls - Array of String URLs.
    # 
    # Checks to see if each URL has already been seen for this Analytics
    # profile.
    # 
    # Returns an Array of new links only.
    def determine_new_links(all_urls)
      all_urls.select {|url| url_exists?(url) == false }
    end

    # Hash a given URL.
    # 
    # url - String URL.
    # 
    # Hashes the URL according to the current profile (@profile_id).
    # 
    # Returns a String hashed URL.
    def hash_url(url)
      Digest::SHA1.hexdigest "#{@profile_id}-#{url}"
    end

    # Determines if the given URL exists in the database.
    # 
    # url - String URL.
    # 
    # Hashes the URL and checks to see if it exists in the database.
    # 
    # Returns a Boolean.
    def url_exists?(url)
      doc = @db[LINKS_COLLECTION_NAME].find_one('_id' => hash_url(url))
      doc.nil? == false
    end

    # Adds new links into the database.
    # 
    # urls - Array of String URLs.
    # 
    # Hashes each URL and does a bulk insert into the links collection.
    # 
    # Returns the result of the DB operation.
    def add_new_urls(urls)
      return if urls.length == 0
      @db[LINKS_COLLECTION_NAME].insert(urls.map {|u| {'_id' => hash_url(u)}})
    end
  end
end
