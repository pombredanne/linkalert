require 'rubygems'
require 'bundler/setup'
require 'date'
require 'erb'
require 'mongo'
require './lib/link_alert'


config = YAML::load(ERB.new(File.read('config.yml')).result)


mongo_client = Mongo::MongoClient.from_uri(config['mongo_url'])
db = mongo_client[config['mongo_url'].split('/').last]

account = LinkAlert::AnalyticsAccount.new(
  db,
  config['api']['client_id'],
  config['api']['client_secret']
)


profiles = ['56543886', '61926118']
fetcher = LinkAlert::LinkFetcher.new(account)


profiles.each do |profile_id|
  links = fetcher.links_for_profile(profile_id)
  # TODO: update links db
  # TODO: keep new links
end


# TODO: send email with new links
# TODO: update last_checked
