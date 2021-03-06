module MongoEmbeddedRecord
  extend ActiveSupport::Concern

  # make ActionPack happy : include ActiveModel::Naming and define instance method to_key
  included do
    extend ActiveModel::Naming
  end

  def self.json_encoder(r)
    case r
    when BSON::ObjectId
      r.to_s
    when Array
      r.map{|i| json_encoder(i)}
    when Hash
      h = {}
      r.each do |k,v|
        if k == '_id'
          h['id'] = json_encoder(v)
        else
          h[k] = json_encoder(v)
        end
      end
      h
    else
      r
    end
  end

  module ClassMethods

    def key(attribute_name)
      define_method attribute_name do
        attributes[attribute_name.to_s]
      end
      define_method "#{attribute_name}=" do |v|
        attributes[attribute_name.to_s] = v
      end
    end

    # idea from mongomapper.
    def embeddable?
      !self.ancestors.include?(MongoRecord)
    end

  end

  module InstanceMethods

    # keep the original attributes hash for embedded record
    # call setter if exist though for normal record (examples: virtual attributes like file data, home made dirty checks)
    def initialize(attributes={})
      if self.class.embeddable?
        @attributes = attributes
        @attributes["_id"] ||= BSON::ObjectId.new 
      else
        @attributes = {}
        id = attributes.delete('_id')
        @attributes["_id"] = id if id
        attributes.each do |attr, v|
          next if attr == '_id'
          if respond_to? "#{attr}="
            send("#{attr}=",v)
          else
            @attributes[attr.to_s] = v
          end
        end
      end
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

    def to_json
      MongoEmbeddedRecord.json_encoder(attributes).to_json
    end

    def attributes=(new_attributes)
      new_attributes.each do |attr,v|
        send("#{attr}=",v)
      end
    end

  end

end
