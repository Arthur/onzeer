class UserVote

  include MongoRecord

  key :album_id #, String, :required => true
  key :author_id #, String, :required => true
  key :note #, Integer, :required => true

  # timestamps TODO

  def album
    @album ||= album_id && Album.find(album_id)
  end

  def author
    @author ||= author_id && User.find(author_id)
  end

end
