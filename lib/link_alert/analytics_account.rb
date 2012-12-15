require 'date'
require 'google/api_client'


module LinkAlert

  class AnalyticsAccount

    # The Google Analytics API access level.
    AUTH_SCOPE = 'https://www.googleapis.com/auth/analytics.readonly'

    # The name of the collection where account details are kept.
    ACCOUNT_COLLECTION_NAME = 'account'

    # Initialize the analytics account.
    # 
    # db - Mongo::Database instance.
    # client_id - String client ID from the Google API console.
    # client_secret - String client secret from the Google API console.
    # 
    # Sets the @client instance variable to a Google::APIClient instance.
    def initialize(db, client_id, client_secret)
      @db = db
      @client = analytics_api_client(client_id, client_secret)
    end

    # Get an instance of the Analytics API client.
    # 
    # Returns a Google::APIClient::API instance for v3 of the Analytics API.
    def analytics
      return @analytics if @analytics
      @analytics = @client.discovered_api('analytics', 'v3')
    end

    # Get the account document.
    # 
    # The analytics oauth token, as well as preferences (which profiles are
    # active, e-mail addresses to send alerts to) are stored in the
    # ACCOUNT_COLLECTION_NAME collection in MongoDB. There should only be one
    # document in that collection.
    # 
    # Returns a Hash with all account data saved in the database, or nil if
    # the account is not setup yet.
    def account
      return @account if @account
      @account = @db[ACCOUNT_COLLECTION_NAME].find_one()
    end

    # Set a new access token.
    # 
    # new_token - String access token.
    # 
    # Once the initial access token has expired, the API client library
    # refreshes it using the refresh_token. When that happens, we save the
    # newer access_token here for future use.
    # 
    # Returns the result of the DB operation.
    def access_token=(new_token)
      if setup?
        @account = nil
        @db[ACCOUNT_COLLECTION_NAME].update(
          {'_id' => account['_id']},
          {'$set' => {access_token: new_token}}
        )
      end
    end

    # Check if a Google Analytics account has been setup.
    #
    # Returns a Boolean.
    def setup?
      account != nil
    end

    # Save the access credentials in the database.
    # 
    # access_token - String access token from Google oauth.
    # refresh_token - String refresh token from Google oauth.
    # 
    # Saves the access and refresh tokens into the database, and sets the last
    # checked date to nil.
    # 
    # Returns the result of the DB insert.
    def add_account(access_token, refresh_token)
      @db[ACCOUNT_COLLECTION_NAME].insert({
        access_token: access_token,
        refresh_token: refresh_token,
        emails: [],
        profiles: {},
        last_checked: nil
      })
    end

    # Get the date on which the last update was run.
    # 
    # The worker process should be run either daily or weekly. The date on
    # which it was last run is recorded in the database, so that the next
    # run will start where the last one ended.
    # 
    # If there hasn't been an update run yet, then we default to 6 months ago.
    # 
    # Returns a Date.
    def last_checked
      if setup? and account['last_checked'] != nil
        Date.parse(account['last_checked'])
      else
        six_months = 30 * 6
        Date.today - six_months
      end
    end

    # Set the last checked date.
    # 
    # new_date - Date on which the latest run was performed.
    # 
    # Returns the result of the DB operation.
    def last_checked=(new_date)
      if setup?
        @account = nil
        @db[ACCOUNT_COLLECTION_NAME].update(
          {'_id' => account['_id']},
          {'$set' => {last_checked: new_date}}
        )
      end
    end

    # Get the email addresses that alerts are sent to.
    # 
    # Returns an Array of email addresses.
    def emails
      account['emails'] if setup?
    end

    # Set the email addresses to send alerts to.
    # 
    # email_addresses - Array of email addresses.
    # 
    # Returns the result of the DB operation.
    def emails=(email_addresses)
      if setup?
        @account = nil
        @db[ACCOUNT_COLLECTION_NAME].update(
          {'_id' => account['_id']},
          {'$set' => {emails: email_addresses}}
        )
      end
    end

    # Get a list of Analytics profiles.
    # 
    # Does a live API request and returns a list of all profiles that the
    # current user has access to.
    # 
    # Returns an Array of Hashes with the keys :id, :name, and :url.
    def available_profiles
      params = {
        api_method: analytics.management.profiles.list,
        parameters: {accountId: '~all', webPropertyId: '~all'}
      }

      api_call(params) do |response|
        return response['items'].map do |item|
          {id: item['id'], name: item['name'], url: item['websiteUrl']}
        end
      end
    end

    # Get the analytics profiles that are alerted on.
    # 
    # Returns a Hash of { profile_id: profile_name }
    def profiles
      account['profiles'] if setup?
    end

    # Is this profile active?
    # 
    # profile_id - String Analytics profile ID.
    # 
    # Returns a Boolean true if we are alerting on that site, or false if not.
    def profile_active?(profile_id)
      profiles.has_key? profile_id
    end

    # Set the analytics profile IDs to alert on.
    # 
    # selected_profiles - Hash of { profile_id: profile_name }
    # 
    # Returns the result of the DB operation.
    def profiles=(selected_profiles)
      if setup?
        @account = nil
        @db[ACCOUNT_COLLECTION_NAME].update(
          {'_id' => account['_id']},
          {'$set' => {profiles: selected_profiles}}
        )
      end
    end

    # Get all referring URLs for the given profile and time period.
    # 
    # profile_id - String Analytics profile ID.
    # start_date - Date start date.
    # end_date - Date end date.
    # 
    # Does a live API request and returns up to 1,000 referring URLs for the
    # given profile in the given time period. Results are ordered by the
    # number of vists received from each URL.
    # 
    # Returns an Array of Hashes with the keys :domain, :path, and :visits.
    def get_links(profile_id, start_date, end_date)
      params = {
        api_method: analytics.data.ga.get,
        parameters: {
          'ids' => "ga:#{profile_id}",
          'start-date' => start_date.to_s,
          'end-date' => end_date.to_s,
          'metrics' => 'ga:visits',
          'dimensions' => 'ga:source,ga:referralPath',
          'sort' => '-ga:visits'
        }
      }

      api_call(params) do |response|
        return response['rows'].map do |row|
          {domain: row[0], path: row[1], visits: row[2]}
        end
      end
    end

    # Delete the account settings.
    # 
    # This method will remove all oauth tokens, profile IDs, and email
    # addresses. The setup process will have to start again.
    # 
    # Returns the result of the DB operation.
    def delete
      if setup?
        @account = nil
        @db[ACCOUNT_COLLECTION_NAME].remove('_id' => account['_id'])
      end
    end

    # Get the oauth authorization URL for this client.
    # 
    # redirect_url - String URL to send the user to after authorization.
    # 
    # Returns a String URL to redirect the user to for authorization.
    def authorization_url(redirect_url)
      @client.authorization.redirect_uri = redirect_url
      @client.authorization.authorization_uri
    end

    # Get access and refresh tokens from an authorization code.
    # 
    # code - String authorization code sent as a GET param in the oauth flow.
    # 
    # Performs a validation request with the Google oauth endpoint to convert
    # the given authorization code into access and refresh tokens.
    # 
    # Returns a Hash of serialized JSON from the Google oauth endpoint. Keys
    # of importance in the Hash are 'access_token' and 'refresh_token'.
    def tokens_from_authorization_code(code)
      @client.authorization.code = code
      @client.authorization.fetch_access_token!
    end


    protected

    # Construct a Google Analytics API client.
    # 
    # client_id - String client ID from the Google API console.
    # client_secret - String client secret from the Google API console.
    # 
    # Returns a Google::APIClient instance.
    def analytics_api_client(client_id, client_secret)
      client = Google::APIClient.new
      client.authorization.scope = AUTH_SCOPE

      client.authorization.client_id = client_id
      client.authorization.client_secret = client_secret

      client
    end

    # Perform an Analytics API call.
    # 
    # params - Hash of parameters to pass to the Analytics API.
    # 
    # Checks the result of the request and if no errors occurred, yields to
    # a block passing in the parsed JSON response.
    # 
    # The Goole API client handles refreshing oauth tokens automatically. If
    # that occurs during a given request, the new access token will be
    # updated in the database.
    # 
    # Returns nil.
    def api_call(params)
      # Set the oauth tokens if needed.
      if @client.authorization.access_token.nil?
        @client.authorization.access_token = account['access_token']
        @client.authorization.refresh_token = account['refresh_token']
      end

      result = @client.execute(params)

      unless result.error?
        # If the access token has been refreshed, save it in the db.
        if @client.authorization.access_token != account['access_token']
          access_token = @client.authorization.access_token
        end

        # Call the passed in block with the result body
        yield JSON.parse(result.body)
      end
    end
  end
end
