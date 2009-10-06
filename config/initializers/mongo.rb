# Initialize the connection to MongoDB and the choice of database.
# It reads all necessary parameters from "config/mongo.yml".
require 'mongomapper'

begin
  mongo_config_file = File.join(Rails.root, "config/mongo.yml")
  mongo_config = YAML.load_file(mongo_config_file)[Rails.env]
rescue
  raise IOError, "config/mongo.yml could not be loaded."
end

database_name = mongo_config['database'] || (raise ArgumentError.new("No MongoDB database name was set for the environment #{Rails.env}, please check 'config/mongo.yml'."))
host = mongo_config['host'] || '127.0.0.1'
port = mongo_config['port'] || 27017

# Initialize the connection to MongoDB
MongoMapper.connection = XGen::Mongo::Driver::Mongo.new(host, port, :auto_reconnect => true)
# Open TCP connection to the MongoDB, and select the database
MongoMapper.database = database_name

if mongo_config['username']
  MongoMapper.database.authenticate(mongo_config['username'], mongo_config['password'])
end
