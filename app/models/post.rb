class Post

  include MongoRecord
  include Timestamp

  key :title #, String, :required => true
  key :body # String, :required => true
  key :author_id #, String, :required => true

  many :comments

  def before_save
    set_timestamps(comments)
  end

  def author
    @author ||= User.find(author_id)
  end

end
