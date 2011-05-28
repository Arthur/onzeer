class TrackListening

  # include MongoMapper::Document
  # include Timestamp
  # 
  # timestamps
  include MongoRecord

  key :track_id #, String, :required => true
  key :user_id #, String, :required => true

  # belongs_to :track
  # belongs_to :user

  def album
    track && track.album
  end

end
