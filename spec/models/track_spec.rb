require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Track do
  def new_track(attributes={})
    Track.new({
      :artist => 'an artist',
      :album_name => 'an album',
      :title => 'a title',
      :nb => 1,
      :seconds => 24,
      :format => 'mp3',
      :file => 'buggy path',
    }.merge(attributes))
  end

  def create_track!(attributes={})
    t = new_track(attributes)
    t.save!
    t
  end

  it { new_track.save!.should be_true }

  it "create an album object" do
    track = create_track!
    track.album.should_not be_nil
    track.album.artist.should == track.artist
    track.album.name.should == track.album_name
    track.album.tracks.should include(track)
  end

  it "should change of album object" do
    track = create_track!
    old_album = track.album
    track.artist = "new one"
    track.save
    track.album.artist.should == track.artist
    track.album.tracks.should include(track)

    track.album.should_not == old_album
    old_album.tracks.should_not include(track)
  end

end
