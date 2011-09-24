class UserComment

  include MongoRecord

  key :album_id #, String, :required => true
  key :comment_id#, String, :required => true
  key :author_id#, String, :required => true

  # TODO
  # include Timestamp
  # timestamps

  def comment
    @comment ||= album.comments.detect{|c| c.id == comment_id}
  end

  def album
    @album ||= album_id && Album.find(album_id)
  end

  def author
    @author ||= author_id && User.find(author_id)
  end

end
