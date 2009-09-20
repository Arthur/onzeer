class Track
  include MongoMapper::Document
  include Timestamp

  timestamps

  key :artist, String, :required => true
  key :album_name, String, :required => true
  key :album_id, String
  key :title, String, :required => true
  key :nb, Integer, :required => true
  key :published, Boolean
  key :year, Integer
  key :bitrate, Integer
  key :seconds, Integer, :required => true
  key :format, String, :required => true
  key :cover, String
  key :file, String, :required => true

  after_save :set_album

  def set_album
    if album.nil? || album.artist != artist || album.name != album_name
      old_album = album
      self.album = Album.find_or_create_by_artist_and_name(artist, album_name)
      album.add_track(self)
      album.save
      if old_album
        old_album.remove_track(self)
        old_album.save
      end
      self.save
    end
  end

  def album
    @album ||= Album.find(album_id) rescue nil if album_id
  end

  def album=(album)
    self.album_id = album.id
    @album = album
  end

  def self.from_file(file)
    info = TrackInfo.new(file)
    return nil unless info[:artist] && info[:album] && info[:title]
    track = new(
      :artist => info[:artist],
      :album_name => info[:album],
      :title => info[:title],
      :nb => info[:track_nb],
      :year => info[:date],
      :bitrate => info[:bitrate],
      :seconds => info[:seconds],
      :format => info[:extension],
      :cover => info[:cover] && Digest::MD5.hexdigest(info[:cover]),
      :file => file
    )
    track.save
    track
  end

end