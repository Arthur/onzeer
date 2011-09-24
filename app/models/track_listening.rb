class TrackListening

  # include MongoMapper::Document
  # include Timestamp
  # 
  # timestamps
  include MongoRecord

  key :track_id #, String, :required => true
  key :user_id #, String, :required => true

  def album
    track && track.album
  end

  def user
    @user ||= user_id && User.find(user_id)
  end

  def track
    @track ||= track_id && Track.find(track_id)
  end

end
