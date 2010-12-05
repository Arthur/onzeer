class User

  include MongoMapper::Document
  include Timestamp

  timestamps
  key :email, String, :required => true
  key :nickname, String
  key :activated, Boolean
  key :roles, Array

  many :user_lists

  def roles_str
    roles.join(', ')
  end

  def roles_str=(string)
    self.roles = string.split(/\s*,\s*/)
  end

  def admin?
    roles.include?("admin")
  end

  def last_votes(page = 1)
    UserVote.paginate(:order => 'created_at DESC', :conditions => {:author_id => id}, :per_page => 10, :page => page)
    # FIXME : conditions to have only positive votes
    # .select{|v| v.note > 0}
  end

  def last_uploaded_albums(page = 1)
    Album.paginate(:order => 'created_at DESC', :conditions => {:user_id => id}, :per_page => 10, :page => page)
  end

  def list_by_id(id)
    list = user_lists.detect{|l| l.list_id == id}
    list.user = self if list
    list
  end

end
