module MongoRecord
  extend ActiveSupport::Concern

  included do
    extend ActiveModel::Naming
    include MongoEmbeddedRecord
  end

  class Paginator
    def initialize(current_page, per_page, records_in_page, total_count)
      @current_page = current_page
      @per_page = per_page
      @records_in_page = records_in_page
      @total_count = total_count
    end
    attr_reader :current_page, :per_page, :records_in_page, :total_count

    def total_pages
      (total_count.to_f/per_page).ceil
    end

    def total_entries; total_count; end
    def page; current_page; end

    def previous_page
      page > 1 ? page - 1 : nil
    end

    def next_page
      page < total_pages ? page + 1 : nil
    end

    def method_missing(name, *args, &block)
      @records_in_page.send(name, *args, &block)
    end
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

    def delete_all(conditions={})
      self.collection.remove(conditions)
    end

    def create(attributes)
      record = new(attributes)
      record.save
      record
    end

    def paginate(params={})
      per_page = params[:per_page]
      per_page ||= 50
      per_page = per_page.to_i
      page = (params[:page] || 1).to_i
      order = params[:order]
      order ||= '_id'

      count = find(params[:conditions] || {}).count
      records = find(params[:conditions] || {}).sort(order).limit(per_page).skip((page-1)*per_page)

      MongoRecord::Paginator.new(page, per_page, records, count)
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
      before_save if respond_to? :before_save
      if new_record?
        create
      else
        update
      end
      after_save if respond_to? :after_save
      true
    end

    def destroy
      self.class.collection.remove({"_id" => id})
    end

    def update_attributes(new_attributes)
      self.attributes = new_attributes
      update
    end

    def create
      Rails.logger.debug("MongoRecord#insert " + [attributes].inspect)
      id = self.class.collection.insert(attributes)
      @attributes['_id'] = attributes.delete(:_id)
    end

    def update
      Rails.logger.debug("MongoRecord#update " + [id,attributes].inspect)
      self.class.collection.update({"_id" => id}, attributes)
    end

  end

end
