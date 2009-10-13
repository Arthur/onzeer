class UserComment
  include MongoMapper::Document
  include Timestamp

  key :album_id, String, :required => true
  key :comment_id, String, :required => true
  key :author_id, String, :required => true
  timestamps

end