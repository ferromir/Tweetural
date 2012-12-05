require 'yaml'
require 'stemmer'
require 'classifier'
require 'rest-client'
require 'mongo'
require 'uri'
require 'json'
require 'ruby-debug'

def data
  return @data if @data
  @data = {}
end

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

  cultures = data[:database].collection("cultures")
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
  lang = "en"
  lang = "es" if culture == "panama"

  response = RestClient.get("http://search.twitter.com/search.json?q=#{text}&lang=#{lang}&result_type=mixed")
  tweets = JSON.parse(response.body)["results"]
end

def classify_tweets(search_text, tweets, culture)
  tweets.map do |tweet|
    tweet["classifications"] = data[:classifiers][culture].classifications(tweet["text"])
    tweet["search_text"] = search_text
    tweet
  end
end

def create_search_results(search_text, culture, classified_tweets)
  search_result = Hash.new(0.0)
  search_result["text"] = search_text
  search_result["culture"] = culture
  search_result["done_at"] = Time.now.to_s
  classified_tweets.each do |ct|
    ct["classifications"].each do |k, v|
      search_result[k] += v
    end
  end
  search_result["classified_tweets"] = classified_tweets
  search_result
end

data[:database] = get_database_from_uri
data[:classifiers] = initialize_classifiers

puts "Search text:"
search_text = gets.chomp.gsub(" ", "%20")
puts "Culture:"
culture = gets.chomp


tweets = search_tweets(search_text, culture)
classified_tweets = classify_tweets(search_text, tweets, culture)

classified_tweets_col = data[:database].collection("classified_tweets")
classified_tweets_col.remove()

classified_tweets.each { |ct| puts classified_tweets_col.insert(ct) }




search_results_col = data[:database].collection("search_results")
search_results_col.remove()
search_result = create_search_results(search_text, culture, classified_tweets)

search_results_col.insert(search_result)



