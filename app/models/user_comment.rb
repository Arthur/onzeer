class UserComment
  include MongoMapper::Document
  include Timestamp

  key :album_id, String, :required => true
  key :comment_id, String, :required => true
  key :author_id, String, :required => true
  timestamps

  belongs_to :album

  def comment
    @comment ||= album.comments.detect{|c| c.id == comment_id}
  end

end
