class UserVote
  include MongoMapper::Document
  include Timestamp

  key :album_id, String, :required => true
  key :author_id, String, :required => true
  key :note, Integer, :required => true
  timestamps


  def album
    @album ||= Album.find(album_id)
  end

  def author
    @author ||= User.find(author_id)
  end

end
