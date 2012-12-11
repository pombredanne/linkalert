module LinkAlert

  class LinkFetcher

    # Initialize the LinkFetcher class.
    # 
    # account - LinkAlert::AnalyticsAccount instance.
    # 
    # Returns a new LinkFetcher instance.
    def initialize(account)
      @account = account
    end

    # Download all new links for the given profile ID.
    # 
    # profile_id - String Analytics profile ID.
    # 
    # Downloads all referring URLs for the given profile, starting on the date
    # of the last update (account.last_checked), and ending yesterday.
    # 
    # Returns an Array of all referring URLs.
    def links_for_profile(profile_id)
      raw_urls = download_links_since_last_update(profile_id)
      process_links(raw_urls)
    end

    # Get all traffic sources for the given profile.
    # 
    # profile_id - String Analytics profile ID.
    # 
    # This method will fetch ALL traffic sources, including direct and search
    # engine referrers.
    # 
    # Returns an Array of Hashes with the keys :domain, :path, and :visits.
    def download_links_since_last_update(profile_id)
      # yesterday
      @account.get_links(profile_id, @account.last_checked, Date.today)
    end

    # Remove unwanted traffic sources.
    # 
    # raw_urls - Array of Hashes returned by download_links_since_last_update.
    # 
    # Removes direct traffic and search engine referrers from the raw URL
    # results, and then combines the domain and path fields into a string.
    # 
    # Returns an Array of Strings, each of a full referring URL.
    def process_links(raw_urls)
      raw_urls.map {|d| "#{d[:domain]}#{d[:path]}" if d[:path] != '(not set)'}.compact
    end
  end
end
