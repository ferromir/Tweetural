require 'yaml'
require 'mongo'
require 'uri'

def get_connection
  return @db_connection if @db_connection
  db = URI.parse(ENV['MONGODB_URI'])
  db_name = db.path.gsub(/^\//, '')
  @db_connection = Mongo::Connection.new(db.host, db.port).db(db_name)
  @db_connection.authenticate(db.user, db.password) unless (db.user.nil? || db.password.nil?)
  @db_connection
end

def save_training_phrases
  cultures = get_connection.collection('cultures')
  cultures.remove()

  training_data = YAML::load_file('training.yml')
  training_data['cultures'].each { |c| cultures.insert(c) }
end

save_training_phrases