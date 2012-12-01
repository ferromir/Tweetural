# command to run this script in OSX:
# $ export MONGOHQ_URL=mongodb://dummy:dummy@alex.mongohq.com:10044/Tweetural;ruby apitest.rb

require 'rest-client'
require 'sinatra'
require 'mongo'
require 'uri'
require 'json'
require 'ruby-debug'

def get_connection
	return @db_connection if @db_connection
	db = URI.parse(ENV['MONGOHQ_URL'])
	db_name = db.path.gsub(/^\//, '')
	@db_connection = Mongo::Connection.new(db.host, db.port).db(db_name)
	@db_connection.authenticate(db.user, db.password) unless (db.user.nil? || db.password.nil?)
	@db_connection
end

db = get_connection

get '/search/:data' do
	response = RestClient.get('http://search.twitter.com/search.json?q=' + params[:data])
	response.body
end

get '/collections' do
	db.collections.to_s
end