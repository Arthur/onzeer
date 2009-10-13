class Album

  include MongoMapper::Document
  include Timestamp

  after_save :update_tracks

  key :artist, String, :required => true
  key :name, String, :required => true
  key :track_ids, Array, :required => true
  key :cover, String
  key :amazon_asin, String
  key :musicbrainz_release_id, String

  timestamps

  many :votes
  many :comments

  def tracks
    return @tracks if @tracks
    @tracks = Track.find(:all, :conditions => {:_id => track_ids}, :order => 'nb')
  end

  def artist=(value)
    @need_tracks_update = true
    self[:artist] = value
  end

  def name=(value)
    @need_tracks_update = true
    self[:name] = value
  end

  def save_user_comment_for(comment)
    UserComment.create(:album_id => id, :comment_id => comment.id, :author_id => comment.author_id)
  end

  def update_tracks
    return unless @need_tracks_update
    tracks.each do |track|
      track.update_attributes(:artist => artist, :album_name => name) unless track.album_name == name && track.artist == artist
    end
  end
  protected :update_tracks

  def find_cover
    track = tracks.detect{|t| t.cover}
    self.cover = track && track.cover
  end

  def public_cover_path
    cover && Track.public_cover_path(cover)
  end

  def add_track(track)
    track_ids << track.id unless track_ids.include?(track.id)
    self.cover ||= track.cover
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

  def musicbrainz_query
    {
      :query=>"#{name} AND artist:\"#{artist}\"",
      :type=> "release",
      :adv=> "on",
      :handlearguments => 1
    }
  end
# http://musicbrainz.org/doc/MusicBrainzIdentifier
# http://musicbrainz.org/doc/Disc_ID_Calculation
  def discid
    # CDDB1 identifies CDs with a 32-bit number, usually displayed as a hexadecimal number containing 8 digits: XXYYYYZZ.
    # The first two digits (labeled XX) represent a checksum based on the starting times of each track on the CD, mod 255.
    # The next four digits (YYYY) represent the total time of the CD in seconds from the start of the first track to the end of the last track.
    # The last two digits (ZZ) represent the number of tracks on the CD.
    return @discid if @discid
    checksum = 0
    checksum = checksum.modulo(255)
    total_time = tracks.map(&:seconds).sum
    nb = tracks.length
    @discid = "%02x%04x%02x" % [checksum, total_time, nb]
  end
end
