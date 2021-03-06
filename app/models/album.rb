class Album

  include MongoRecord
  include Timestamp

  key :artist #, String, :required => true
  key :name #, String, :required => true
  key :track_ids #, Array, :required => true
  key :cover #, String
  key :amazon_asin #, String
  key :musicbrainz_release_id #, String

  key :user_id #, String # author

  many :votes
  many :comments

  def self.find_randomly(number = 10)
    count = self.count
    (0...number).map{ find().limit(1).skip(rand(count)).first()}.compact
  end

  def self.find_last(page=nil)
    Album.paginate(:order => ['_id', 'descending'], :per_page => 10, :page => page)
  end

  def self.find_or_create_by_artist_and_name(artist,name)
    album = find(:artist => artist, :name => name).first
    return album if album
    album = new(:artist => artist, :name => name)
    album.save
    album
  end

  def before_save
    set_timestamps(comments)
  end

  def after_save
    update_tracks
  end

  def track_ids
    self.attributes['track_ids'] ||= []
  end

  def tracks
    return @tracks if @tracks
    @tracks = Track.find(:_id => {'$in' => track_ids}).sort('nb')
  end

  def artist=(value)
    @need_tracks_update = true
    self.attributes['artist'] = value
  end

  def name=(value)
    @need_tracks_update = true
    self.attributes['name'] = value
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
    UserVote.delete_all(:album_id => id, :author_id => user.id)
    votes.delete_if{|v| v.author_id == user.id}
    votes << Vote.new(:note => 1, :author_id => user.id)
    UserVote.create(:album_id => id, :author_id => user.id, :note => 1)
  end

  def lovers
    @lovers ||= votes.select{|v| v.note > 0}.map(&:author)
  end

  def hated_by(user)
    UserVote.delete_all(:album_id => id, :author_id => user.id)
    votes.delete_if{|v| v.author_id == user.id}
    votes << Vote.new(:note => -1, :author_id => user.id)
    # only create UserVote for positive ones for now.
    # UserVote.create(:album_id => id, :author_id => user.id, :note => -1)
  end

  def haters
    @haters ||= votes.select{|v| v.note < 0}.map(&:author)
  end

  def remove_vote_of(user)
    UserVote.delete_all(:album_id => id, :author_id => user.id)
    votes.delete_if{|v| v.author_id == user.id}
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
