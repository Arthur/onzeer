class MongoCollection

  def initialize(parent,target_name,target_class)
    @parent = parent
    @target_name = target_name
    @target_class = target_class
  end

  def attributes_array
    @parent.attributes[@target_name.to_s] ||= []
  end

  def target
    attributes_array.map{|attr| @target_class.new(attr)}
  end

  def <<(object)
    attributes_array << object.attributes
  end

  def delete_if(&block)
    attributes_array.delete_if{ |attr| yield(@target_class.new(attr)) }
  end

  def method_missing(name, *args, &block)
    target.send(name, *args, &block)
  end

end
