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

  def last_votes(page = 1)
    UserVote.paginate(:order => 'created_at DESC', :conditions => {:author_id => id}, :per_page => 10, :page => page)
    # FIXME : conditions to have only positive votes
    # .select{|v| v.note > 0}
  end

end
