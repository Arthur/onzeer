require 'mongo_record'

class User

  # include MongoMapper::Document
  # include Timestamp
  include ::MongoRecord

  # timestamps
  key :email #, String, :required => true
  key :nickname #, String
  key :activated #, Boolean
  key :roles #, Array

  many :user_lists

  def self.find_or_create_by_email(email)
    user = find(:email => email).first
    return user if user
    user = new(:email => email)

    # first user is admin :
    if count == 0
      user.roles = ['admin'] 
      user.activated = true
    end

    user.save
    user
  end

  def roles_str
    (roles || []).join(', ')
  end

  def roles_str=(string)
    self.roles = string.split(/\s*,\s*/)
  end

  def admin?
    (roles || []).include?("admin")
  end

  def activated?
    !!activated
  end

  def last_votes(page = 1)
    # UserVote.paginate(:order => 'created_at DESC', :conditions => {:author_id => id}, :per_page => 10, :page => page)
    UserVote.paginate(:conditions => {:author_id => id}, :order => ['_id', 'descending'], :per_page => 10, :page => page)
    # FIXME : conditions to have only positive votes
    # .select{|v| v.note > 0}
  end

  def last_uploaded_albums(page = 1)
    Album.paginate(:order => ['_id', 'descending'], :conditions => {:user_id => id}, :per_page => 10, :page => page)
  end

  def list_by_id(id)
    list = user_lists.detect{|l| l.list_id == id}
    list.user = self if list
    list
  end

end
