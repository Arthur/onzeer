module MongoRecord
  extend ActiveSupport::Concern

  included do
    extend ActiveModel::Naming
    include MongoEmbeddedRecord
  end

  module ClassMethods
    def mongohq_url
      return @uri unless @uri.nil?
      if ENV['MONGOHQ_URL']
        @uri = URI.parse(ENV['MONGOHQ_URL'])
      else
        @uri = false
      end
    end

    def connection
      return @connection if @connection
      if ENV['MONGOHQ_URL']
        @connection ||= Mongo::Connection.from_uri(ENV['MONGOHQ_URL'])
      else
        @connection ||= Mongo::Connection.new
      end
    end

    def database
      return @database if @database
      if mongohq_url
        @database ||= connection.db(mongohq_url.path.gsub(/^\//, ''))
      else
        @database ||= connection.db(Rails.env.to_s)
      end
    end

    def collection
      @collection ||= database.collection(self.to_s.underscore.pluralize)
    end

    def find(*args)
      if args.empty?
        MongoCursorProxy.new(collection.find(), self)
      elsif args.length == 1
        id_or_query = args.first
        if id_or_query.is_a? Hash
          MongoCursorProxy.new(collection.find(id_or_query), self)
        else
          id = id_or_query
          id = BSON::ObjectId(id) if id.is_a? String
          new(collection.find_one(id))
        end
      else
        raise "#{self}.find(#{args.inspect}) not yet implemented"
      end
    end

    def count
      collection.count
    end

    def all
      find()
    end

    def first()
      find().sort(['_id', 'asc']).limit(1).first
    end

    def last
      find().sort(['_id', 'desc']).limit(1).first
    end

    def many(collection_name)
      define_method collection_name do
        collection = instance_variable_get("@#{collection_name}")
        return collection if collection
        collection = MongoCollection.new(self, collection_name, collection_name.to_s.singularize.camelcase.constantize)
        instance_variable_set("@#{collection_name}", collection)
        return collection
      end
    end
  end

  module InstanceMethods

    def new_record?
      !id
    end
    def persisted?
      !new_record?
    end

    def ==(other)
      other.class == self.class && other.attributes == attributes
    end

    def save
      if new_record?
        create
      else
        update
      end
    end

    def destroy
      self.class.collection.remove({"_id" => id})
    end

    def update_attributes(new_attributes)
      self.attributes = new_attributes
      update
    end

    def create
      id = self.class.collection.insert(attributes)
      @attributes['_id'] = attributes.delete(:_id)
    end

    def update
      self.class.collection.update({"_id" => id}, attributes)
    end

  end

end
