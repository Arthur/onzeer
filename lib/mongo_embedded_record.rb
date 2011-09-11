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

  end

  module InstanceMethods

    def initialize(attributes={})
      @attributes = {}
      self.attributes = attributes.stringify_keys!
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
