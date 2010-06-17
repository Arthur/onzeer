class User

  include MongoMapper::Document
  include Timestamp

  timestamps
  key :email, String, :required => true
  key :nickname, String
  key :activated, Boolean
  key :roles, Array

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
    UserVote.find_all_by_author_id(id, :order => 'created_at DESC', :limit => 10).select{|v| v.note > 0}.map(&:album_id).uniq.map{|album_id| Album.find(album_id)}
  end

end
