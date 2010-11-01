class Post

  include MongoMapper::Document
  include Timestamp
  timestamps

  key :title, String, :required => true
  key :body, String, :required => true
  key :author_id, String, :required => true
  belongs_to :author, :class_name => "User"

  many :comments

end
