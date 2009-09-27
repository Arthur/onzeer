class Album

  include MongoMapper::Document
  include Timestamp

  after_save :update_tracks

  key :artist, String, :required => true
  key :name, String, :required => true
  key :track_ids, Array, :required => true
  timestamps

  many :votes
  many :comments

  def tracks
    return @tracks if @tracks
    @tracks = Track.find(:all, :conditions => {:_id => track_ids})
  end

  def artist=(value)
    @need_tracks_update = true
    self[:artist] = value
  end

  def name=(value)
    @need_tracks_update = true
    self[:name] = value
  end

  def update_tracks
    return unless @need_tracks_update
    tracks.each do |track|
      track.update_attributes(:artist => artist, :album_name => name) unless track.album_name == name && track.artist == artist
    end
  end
  protected :update_tracks

  def add_track(track)
    track_ids << track.id unless track_ids.include?(track.id)
  end

  def remove_track(track)
    track_ids.delete(track.id) if track_ids.include?(track.id)
  end

  def loved_by(user)
    votes.delete_if{|v| v.author_id == user.id}
    votes << Vote.new(:note => 1, :author => user)
  end

  def lovers
    @lovers ||= votes.select{|v| v.note > 0}.map(&:author)
  end

  def hated_by(user)
    votes.delete_if{|v| v.author_id == user.id}
    votes << Vote.new(:note => -1, :author => user)
    RAILS_DEFAULT_LOGGER.debug ["hated_by", user, votes].inspect
  end

  def haters
    @haters ||= votes.select{|v| v.note < 0}.map(&:author)
  end

end