class Comment

  include MongoMapper::EmbeddedDocument
  include Timestamp

  belongs_to :author, :class_name => "User"
  key :author_id, String, :required => true
  key :body, String, :required => true
  timestamps

  def to_param
    id
  end

end
