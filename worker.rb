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

fetcher = LinkAlert::LinkFetcher.new(account)
result = {}


account.profiles.each do |profile_id, profile_name|
  # Get all links for this period.
  all_links = fetcher.links_for_profile(profile_id)

  # Determine which of them are new.
  checker = LinkAlert::LinkChecker.new(db, profile_id)
  new_links = checker.determine_new_links(all_links)
  result[profile_id] = new_links

  # Add the new links to the DB for next time.
  checker.add_new_urls(new_links)
end


num_links = 0
result.each do |profile_id, links|
  num_links += links.count
end

if num_links > 0
  # Send the email alert to each address.
  mailer = LinkAlert::Mailer.new(
    config['postmark_api_key'],
    config['postmark_from_email'],
    account.profiles
  )
  mailer.build_message(result)

  account.emails.each { |email| mailer.deliver_to(email) }

  # Update last checked at to yesterday, which is the last day of links
  # we checked.
  yesterday = Date.today - 1
  account.last_checked = yesterday
end
