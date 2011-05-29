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

  # many :user_lists

  def self.find_or_create_by_email(email)
    user = find(:email => email).first
    return user if user
    user = new(:email => email)

    # first user is admin :
    user.roles = [admin] if count == 0

    user.save
    user
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

  def last_votes(page = 1)
    # UserVote.paginate(:order => 'created_at DESC', :conditions => {:author_id => id}, :per_page => 10, :page => page)
    UserVote.find(:author_id => id).sort(['_id', 'descending']).limit(10).skip((page-1)*10)
    # FIXME : conditions to have only positive votes
    # .select{|v| v.note > 0}
  end

  def last_uploaded_albums(page = 1)
    # Album.paginate(:order => 'created_at DESC', :conditions => {:user_id => id}, :per_page => 10, :page => page)
    Album.find(:user_id => id).sort(['_id', 'descending']).limit(10).skip((page-1)*10)
  end

  def list_by_id(id)
    list = user_lists.detect{|l| l.list_id == id}
    list.user = self if list
    list
  end

end
