require 'mongo'
require 'uri'
require 'json'
equire 'yaml'
require 'stemmer'
require 'classifier'

def get_connection
  return @db_connection if @db_connection
  db = URI.parse("mongodb://test:test@alex.mongohq.com:10044/Tweetural")
  db_name = db.path.gsub(/^\//, '')
  @db_connection = Mongo::Connection.new(db.host, db.port).db(db_name)
  @db_connection.authenticate(db.user, db.password) unless (db.user.nil? || db.user.nil?)
  @db_connection
end

db = get_connection
