module MongoEmbeddedRecord
  extend ActiveSupport::Concern

  # make ActionPack happy : include ActiveModel::Naming and define instance method to_key
  included do
    extend ActiveModel::Naming
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

    def initialize(attributes={})
      @attributes = {}
      id = attributes.delete("_id")
      @attributes["_id"] = id if id
      @attributes["_id"] ||= BSON::ObjectId.new if self.class.embeddable?
      attributes.each do |attr, v|
        if respond_to? "#{attr}="
          send("#{attr}=",v)
        else
          @attributes[attr.to_s] = v
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

    def attributes=(new_attributes)
      new_attributes.each do |attr,v|
        send("#{attr}=",v)
      end
    end

  end

end
