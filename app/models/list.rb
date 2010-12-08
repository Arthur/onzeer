class List
  include MongoMapper::Document

  key :name, String, :required => true
  many :modifications
  key :author_id, String, :required => true
  # belongs_to :author, :class_name => "User"

  include Timestamp
  timestamps

  after_save :create_author_user_list

  def author=(author)
    self.author_id = author.id
  end

  def author
    @author ||= author_id && User.find(author_id)
  end

  def add(params)
    add_or_remove(:add, params)
  end

  def remove(params)
    add_or_remove(:remove, params)
  end

  def follow_by(user)
    user_list = user.list_by_id(id)
    return user_list if user_list
    user_list = UserList.new(:name => name, :list_id => id)
    user.user_lists << user_list
    user.save
    modifications.each do |modification|
      modification.list = self
      modification.accept(:author => user)
    end
    user_list
  end

  def add_or_remove(action, params)
    author_id = params[:author_id]
    author_id ||= params[:author] && params[:author].id
    album_id = params[:album_id]
    raise "missing :author_id or author" unless author_id
    raise "missing :album_id" unless author_id
    author = params[:author] || User.find(author_id)
    user_list = follow_by(author)
    modification = Modification.new(:author_id => author_id, :action => action.to_s, :album_id => album_id)
    modification.list = self
    modifications << modification
    save
    modification.accept(:author => author)
  end

protected
  def create_author_user_list
    user_list = author.list_by_id(id)
    unless user_list
      user_list = UserList.new(:name => name, :list_id => id)
      author.user_lists << user_list
      author.save
    end
  end


end
