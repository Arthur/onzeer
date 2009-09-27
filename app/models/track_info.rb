require 'mp4info'
require 'mp3info'

class TrackInfo
  def initialize(filename, content_type=nil)
    @filename = filename
    @content_type = content_type
  end
  attr_accessor :filename
  attr_accessor :content_type

  def format
    if content_type
      return :mp3 if content_type == "audio/mpeg"
      return :aac if content_type == "audio/x-m4a"
    end
    return :mp3 if filename =~ /\.mp3$/i
    return :aac if filename =~ /\.m4a$/i
  end

  def aac?; format == :aac; end
  def mp3?; format == :mp3; end

  def to_hash
    return nil if @hash == false
    return @hash if @hash
    @hash = false
    if aac?
      info = MP4Info.open(filename)
      track_nb = info.TRKN
      track_nb = track_nb.first if track_nb && track_nb.length == 2
      @hash = {
        :album => info.ALB, 
        :artist => info.AART || info.ART,
        :track_nb => track_nb, 
        :title => info.NAM,
        :date => info.DAY,
        :size => info.SIZE,
        :seconds => info.SECS,
        :cover => info.COVR,
        :ms => info.ms,
        :frequency => info.FREQUENCY,
        :encoding => info.ENCODING,
        :bitrate => info.BITRATE,
        :extension => :m4a,
      }
    end
    if mp3?
      Mp3Info.open(filename) do |mp3|
        @hash = {
          :album => mp3.tag.album,
          :artist => mp3.tag.artist,
          :track_nb => mp3.tag.tracknum,
          :title => mp3.tag.title,
          :date => mp3.tag.year,
          :bitrate => mp3.bitrate,
          :seconds => mp3.length,
          :cover => mp3.tag2["PIC"],
          :extension => :mp3,
        }
      end
    end
    @hash
  end

  def [](k)
    to_hash && to_hash[k]
  end

  ILLEGAL_PATH_CHARS = /(\/|\\|\|:|'|\s)/
  def path_no_slash
    @path_no_slash ||= 
      File.join(
        self[:artist].gsub(ILLEGAL_PATH_CHARS,'_'),
        self[:album].gsub(ILLEGAL_PATH_CHARS,'_'),
        "#{"%02u" % self[:track_nb]}-#{self[:title]}.#{self[:extension]}".gsub(ILLEGAL_PATH_CHARS,'_')
      )
  end

  def inspect
    "%35s | %40s | %02u %55s | (%04u) [%04u] @ %03u %s %s" % 
      [self[:artist], self[:album], self[:track_nb], self[:title], self[:seconds], self[:date], self[:bitrate], self[:extension], self[:cover] && self[:cover].length]
  end
end
