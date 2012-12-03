require 'rest-client'
require 'mongo'
require 'uri'
require 'json'
require 'ruby-debug'

def get_database_from_uri
  return @db_connection if @db_connection
  db = URI.parse(ENV['MONGODB_URI'])
  db_name = db.path.gsub(/^\//, '')
  @db_connection = Mongo::Connection.from_uri(ENV['MONGODB_URI']).db(db_name)
  @db_connection.authenticate(db.user, db.password) unless (db.user.nil? || db.password.nil?)
  @db_connection
end

def save_tweets(new_tweets)
  feed_tweets = get_database_from_uri.collection('feed_tweets')
  new_tweets.each { |t| feed_tweets.insert(t) }
end

def search(text)
  response = RestClient.get("http://search.twitter.com/search.json?q=#{text}&lang=es&result_type=mixed")
  search_result = JSON.parse(response.body)
  save_tweets(search_result['results'])
end

search('cambio%20democratico')
search('Ricardo%20Martinelli')
search('panamenista')
search('Juan&%20Carlos%20Varela')
search('PRD')
search('Juan&%20Carlos%20Navarro')
search('panama')