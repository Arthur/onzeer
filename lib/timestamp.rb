module Timestamp
  def self.included(base)
    base.before_save :set_timestamp if base.respond_to?(:before_save)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def timestamps
      key :created_at, Time
      key :updated_at, Time
    end
  end

  def set_timestamp
    current_time = Time.now.utc

    self.created_at = current_time if new? && respond_to?(:created_at)
    self.updated_at = current_time if respond_to?(:updated_at)
  end

end