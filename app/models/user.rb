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

end