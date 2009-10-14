class UserVote
  include MongoMapper::Document
  include Timestamp

  key :album_id, String, :required => true
  key :author_id, String, :required => true
  key :note, Integer, :required => true
  timestamps

  belongs_to :album
  belongs_to :author, :class_name => "User"

end
