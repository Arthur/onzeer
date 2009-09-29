class User

  include MongoMapper::Document
  include Timestamp

  timestamps
  key :email, String, :required => true
  key :nickname, String
  key :activated, Boolean
  key :roles, Array

  before_save :open_bar

  def open_bar
    self.activated = true
  end

  def roles_str
    roles.join(', ')
  end

  def roles_str=(string)
    self.roles = string.split(/\s*,\s*/)
  end

  def admin?
    roles.include?("admin")
  end

  def last_preferred_albums
    UserVote.find_all_by_author_id(id, :order => 'created_at DESC', :limit => 10).map{|v| Album.find(v.album_id)}
  end

end
