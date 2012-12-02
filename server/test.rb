require 'uri'
require 'mongo'

uri  = URI.parse(ENV['MONGODB_URI'])
conn = Mongo::Connection.from_uri(ENV['MONGODB_URI'])
db   = conn.db(uri.path.gsub(/^\//, ''))
db.collection_names.each { |name| puts name }