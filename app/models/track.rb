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

  key :user_id, String, :required => true

  after_save :set_album
  after_create :set_public_symlink
  after_save :move_file

  attr_accessor :file_data, :content_type

  def file_data=(data)
    @file_data = data
    return unless data && data.respond_to?(:path) && data.respond_to?(:content_type)
    RAILS_DEFAULT_LOGGER.debug([data, data.path, data.content_type].inspect)
    self.file = file_data.path
    self.content_type = file_data.content_type
    set_attributes_from_file
  end

  def move_file
    RAILS_DEFAULT_LOGGER.debug(["save_file", file_data].inspect)
    if file_data
      path = Rails.root.join('storage', 'tracks', "user_#{user_id}", id[0..1], id[2..3], id[4..-1]+'.'+format)
      FileUtils.mkdir_p(File.dirname(path))
      FileUtils.mv(file, path)
      self.file = path
      self.file_data = nil
      self.save
    end
  end

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

  def set_public_symlink
    dir = Rails.root.join('public', 'audio_files', id[0..1], id[2..3])
    FileUtils.mkdir_p(dir)
    symlink_path = File.join(dir, id[4..-1]+'.'+format)
    FileUtils.ln_s file, symlink_path
  end

  def album
    @album ||= Album.find(album_id) rescue nil if album_id
  end

  def album=(album)
    self.album_id = album.id
    @album = album
  end

  def track_info
    @track_info ||= TrackInfo.new(file, content_type)
  end

  def save_cover
    if cover = track_info[:cover]
      md5 = Digest::MD5.hexdigest(track_info[:cover])
      cover_file = Rails.root.join('public', 'cover_files', md5[0..1], md5[2..3], md5[4..-1]+'.png')
      self.cover = md5
      unless File.exist?(cover_file)
        FileUtils.mkdir_p(File.dirname(cover_file))
        File.open(cover_file,'w') { |file| file.write(cover) }
      end
    end
  end

  def set_attributes_from_file
    self.attributes = {
      :artist => track_info[:artist],
      :album_name => track_info[:album],
      :title => track_info[:title],
      :nb => track_info[:track_nb],
      :year => track_info[:date],
      :bitrate => track_info[:bitrate],
      :seconds => track_info[:seconds],
      :format => track_info[:extension],
    }
  end

  def self.from_file(file)
    track = Track.new(:file => file)
    info = track.info
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
      :file => file
    )
    track.save_cover
    track.save
    track
  end

  def self.all_since(since)
    if since.blank?
      Track.all
    else
      since = DateTime.parse(since)
      Track.all.select{|t| t.updated_at > since}
    end
  end

end