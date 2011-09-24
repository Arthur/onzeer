class MongoCursorProxy

  def initialize(cursor, klass)
    @cursor = cursor
    @klass = klass
  end

  def method_missing(name, *args, &block)
    case name
    when :sort, :limit, :skip
      self.class.new(@cursor.send(name, *args, &block), @klass)
    else
      records.send(name, *args, &block)
    end
  end

  def records
    @records ||= @cursor.map{|attributes| @klass.new(attributes)}
  end

  def count
    @cursor.count
  end

  def to_json
    records.to_json
  end

  def previous_page
    1
  end

  def next_page
    1
  end

end
