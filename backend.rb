require 'yaml'
require 'stemmer'
require 'classifier'
require 'sinatra'
require 'rest-client'
require 'mongo'
require 'uri'
require 'json'
require 'ruby-debug'

enable :sessions

def get_database_from_uri
  return @db_connection if @db_connection
  db = URI.parse(ENV['MONGODB_URI'])
  db_name = db.path.gsub(/^\//, '')
  @db_connection = Mongo::Connection.from_uri(ENV['MONGODB_URI']).db(db_name)
  @db_connection.authenticate(db.user, db.password) unless (db.user.nil? || db.password.nil?)
  @db_connection
end

def initialize_classifiers
  classifiers = {}

  cultures = session[:database].collection("cultures")
  cultures.find({}).each do |culture|
    classifier = (classifiers[culture["name"]] = Classifier::Bayes.new)
    culture["categories"].each do |category|
      classifier.add_category(category["name"])
      category["phrases"].each do |phrase|
        classifier.train(category["name"], phrase)
      end
    end
  end

  classifiers
end

def search_tweets(text, culture)
  lang = "en" if culture == "global"
  lang = "es" if culture == "panama"

  response = RestClient.get("http://search.twitter.com/search.json?q=#{text}&lang=#{lang}&result_type=mixed")
  search_result = JSON.parse(response.body)

  tweets = []
  search_result["results"].each do |full_tweet|
    tweet = {}
    tweet["id"] = full_tweet["id"]
    tweet["from_user"] = full_tweet["from_user"]
    tweet["text"] = full_tweet["text"]
    tweet["created_at"] = full_tweet["created_at"]
    tweets << tweet
  end
  tweets
end

def classify_tweets(tweets, culture)
  tweets.each do |tweet|
    tweet["classifications"] = session[:classifiers][culture].classifications(tweet["text"])
  end
  tweets
end

get '/analyze/:culture/:text' do
  session[:database] ||= get_database_from_uri
  session[:classifiers] ||= initialize_classifiers

  culture = params[:culture]
  text = params[:text]

  tweets = search_tweets(text, culture)
  #classified_tweets = classify_tweets(tweets, culture)

  "Hola!"
end