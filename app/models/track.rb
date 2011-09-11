require 'digest/sha1'

class Track
  # include MongoMapper::Document
  # include Timestamp
  # 
  # timestamps

  include MongoRecord
  key :artist       #, String, :required => true
  key :album_name   #, String, :required => true
  key :album_id     #, String
  key :title        #, String, :required => true
  key :nb           #, Integer, :required => true
  key :published    #, Boolean
  key :year         #, Integer
  key :bitrate      #, Integer
  key :seconds      #, Integer, :required => true
  key :format       #, String, :required => true
  key :cover        #, String
  key :compilation  #, Boolean
  key :sha1

  key :user_id      #, String#, :required => true

  # after_save :set_album
  # after_save :move_file

  attr_accessor :file_data, :content_type, :original_path, :file

  def duration
    min = seconds / 60
    "%u:%02u" % [min, seconds - 60*min]
  end

  def file_data=(data)
    @file_data = data
    RAILS_DEFAULT_LOGGER.info(
      ["file_data", data, 
          data.respond_to?(:path) && data.path,
          data.respond_to?(:content_type) && data.content_type,
          data.respond_to?(:original_path) && data.original_path,
          data.respond_to?(:original_filename) && data.original_filename,
      ].inspect)
    return unless data && data.respond_to?(:path) && (data.respond_to?(:content_type) || data.respond_to?(:original_path))
    RAILS_DEFAULT_LOGGER.debug(["file_data", data, data.path, data.content_type, data.original_path].inspect)
    self.file = file_data.path
    self.content_type   = data.content_type   if data.respond_to?(:content_type)
    self.original_path  = data.original_path  if data.respond_to?(:original_path)
    self.original_path  = data.original_filename  if data.respond_to?(:original_filename)
    set_attributes_from_file
  end

  def save_to_s3
    content = file_data.read
    self.sha1 = Digest::SHA1.hexdigest(content)
    RAILS_DEFAULT_LOGGER.info("trying to upload '#{self.sha1}' to s3")
    new_object = file_bucket.objects.build(self.sha1)
    new_object.content = content
    new_object.content_type = self.content_type
    new_object.save
  end

  def save
    if file_data
      save_to_s3
    end
    RAILS_DEFAULT_LOGGER.info("saving track: "+ attributes.inspect)
    super
  end

  def move_file
    if file_data
      path = Rails.root.join('storage', 'tracks', "user_#{user_id}", id[0..1], id[2..3], id[4..-1]+'.'+format)
      RAILS_DEFAULT_LOGGER.debug(["move_file", file_data, path].inspect)
      FileUtils.mkdir_p(File.dirname(path))
      FileUtils.mv(file, path)
      self.file = path
      self.file_data = nil
      set_public_symlink
      self.save
    end
  end

  def set_album
    album_artist = artist
    album_artist = "Various" if compilation
    if album.nil? || album.artist != album_artist || album.name != album_name
      old_album = album
      self.album = Album.find_or_create_by_artist_and_name(album_artist, album_name)
      album.user_id ||= user_id
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
    @track_info ||= TrackInfo.new(file, content_type, original_path)
  end

  def self.public_cover_path(cover)
    cover && ['cover_files', cover[0..1], cover[2..3], cover[4..-1]+'.png'].join('/')
  end

  def public_cover_path
    self.class.public_cover_path(cover)
  end

  def save_cover
    if cover = track_info[:cover]
      md5 = Digest::MD5.hexdigest(cover)
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
    track.set_public_symlink
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

  def self.want(attributes)
    required_attributes = %w(TrackNumber Name Artist Album)
    missing_attributes = required_attributes.select{|a| attributes[a].blank?}
    return "No, please assign this attributes before : #{missing_attributes.join(', ')}" unless missing_attributes.empty?
    conditions = {:artist => attributes["Artist"], :album_name => attributes["Album"], :nb => attributes["TrackNumber"].to_i}
    RAILS_DEFAULT_LOGGER.debug conditions.inspect
    return "We already have it" if Track.find(:first, :conditions => conditions)
    return "Ok, I want it !"
  end

private
  def s3_service
    @s3_service ||= S3::Service.new(:access_key_id => ENV['S3_KEY_ID'], :secret_access_key => ENV['S3_SECRET'])
  end

  def file_bucket
    @file_bucket ||= s3_service.buckets.find(ENV['S3_BUCKET_PREFIX']+"-audio-files")
  end
end
