module MongoRecord
  extend ActiveSupport::Concern

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
      find().limit(1).first
    end

    def last
      all.last # FIXME
    end

    def key(attribute_name)
      define_method attribute_name do
        attributes[attribute_name.to_s]
      end
      define_method "#{attribute_name}=" do |v|
        attributes[attribute_name.to_s] = v
      end
    end
  end

  module InstanceMethods

    def initialize(attributes={})
      @attributes = attributes.stringify_keys!
    end

    def attributes; @attributes; end

    def id
      attributes['_id']
    end

    def to_param
      id.to_s
    end

    def to_key
      [self.class.to_s.underscore]
    end

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

    def attributes=(new_attributes)
      new_attributes.each do |attr,v|
        send("#{attr}=",v)
      end
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
