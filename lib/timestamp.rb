module Timestamp
  def self.included(base)
    base.extend(ClassMethods)
    base.timestamps
  end

  module ClassMethods
    def timestamps
      key :created_at#, Time
      key :updated_at#, Time
    end
  end

  def set_timestamps(embedded_docs=[])
    current_time = Time.now.utc

    self.created_at = current_time if new_record? && respond_to?(:created_at)
    self.updated_at = current_time if respond_to?(:updated_at)

    embedded_docs.flatten.each do |doc|
      doc.created_at ||= current_time if doc.respond_to?(:created_at)
      doc.updated_at ||= current_time if doc.respond_to?(:updated_at)
    end
  end

end
