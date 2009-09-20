class Vote

  include MongoMapper::EmbeddedDocument
  include Timestamp

  belongs_to :author, :class_name => "User"
  key :author_id, String, :required => true
  key :note, Integer, :required => true
  timestamps

  def author
    @author ||= User.find(author_id)
  end

end
