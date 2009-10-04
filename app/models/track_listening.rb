class TrackListening

  include MongoMapper::Document
  include Timestamp

  timestamps

  key :track_id, String, :required => true
  key :user_id, String, :required => true

end