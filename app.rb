require 'rubygems'
require 'bundler/setup'
require 'date'
require 'json'
require 'mongo'
require 'sinatra'
require './lib/link_alert'


set :config, YAML::load(ERB.new(File.read('config.yml')).result)


use Rack::Auth::Basic do |user, pass|
  user == settings.config['username'] && pass == settings.config['password']
end


mongo_client = Mongo::MongoClient.from_uri(settings.config['mongo_url'])
db = mongo_client[settings.config['mongo_url'].split('/').last]

account = LinkAlert::AnalyticsAccount.new(
  db,
  settings.config['api']['client_id'],
  settings.config['api']['client_secret']
)


get '/' do
  if account.setup?
    @account = account
    erb :index
  else
    redirect_url = to('/oauth_callback')
    @oauth_link = account.authorization_url(redirect_url)
    erb :setup_oauth
  end
end


post '/update_settings' do
  # profiles
  # email addresses
end


get '/oauth_callback' do
  if params[:code]
    tokens = account.tokens_from_authorization_code(params[:code])
    account.add_account(tokens['access_token'], tokens['refresh_token'])
    redirect to('/')
  else
    "You must grant access in order to use this app."
  end
end
