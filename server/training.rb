require 'yaml'
require 'mongo'
require 'uri'

def get_database_from_uri
  return @db_connection if @db_connection
  db = URI.parse(ENV['MONGODB_URI'])
  db_name = db.path.gsub(/^\//, '')
  @db_connection = Mongo::Connection.from_uri(ENV['MONGODB_URI']).db(db_name)
  @db_connection.authenticate(db.user, db.password) unless (db.user.nil? || db.password.nil?)
  @db_connection
end

def save_training_phrases
  cultures = get_database_from_uri.collection('cultures')
  cultures.remove()

  training_data = YAML::load_file('training.yml')
  training_data['cultures'].each { |c| cultures.insert(c) }
end

save_training_phrases