class Paginator

  def initialize(ids, options = {})
    @ids = ids
    @per_page = options[:per_page] ? options[:per_page].to_i : 10
    @page = options[:page] ? options[:page].to_i : 1
    @class = options[:class]
  end

  attr_reader :ids, :page, :per_page

  def pages_count
    (ids.length.to_f/per_page).ceil
  end

  def previous_page
    page > 1 ? page - 1 : nil
  end

  def next_page
    page < pages_count ? page + 1 : nil
  end

  def ids_in_page
    (((page - 1) * per_page)..((page*per_page) - 1)).map{ |i| ids[i] }.compact
  end

  def objects_in_page
    @objects_in_page ||= ids_in_page.map{|id| @class.find(id)}
  end

end
