class MusicBrainzRelease
  include HTTParty
  base_uri 'http://musicbrainz.org/ws/1/release/'
  format :xml

  def self.find_all_by_title_and_artist(title, artist)
    result = MusicBrainzRelease.get('http://musicbrainz.org/ws/1/release/', :query => {:query => "#{title} AND artist:#{artist}", :type => "xml"})
    if result["metadata"] && result["metadata"]["release_list"]
      result = result["metadata"]["release_list"]["release"] if result["metadata"] && result["metadata"]["release_list"]
    else
      result = []
    end
    result = [result] unless result.is_a?(Array)
    result
  end

end

#  MusicBrainzRelease.get('http://musicbrainz.org/ws/1/release/f1ce224e-cdd4-49b3-a7d7-61178027922c?type=xml&inc=tracks')
# => {"metadata"=>{"xmlns:ext"=>"http://musicbrainz.org/ns/ext-1.0#", "release"=>{"title"=>"Time 4 Change", "text_representation"=>{"script"=>"Latn", "language"=>"ENG"}, "type"=>"Album Official", "id"=>"f1ce224e-cdd4-49b3-a7d7-61178027922c", "asin"=>"B000050G37", "track_list"=>{"track"=>[{"title"=>"Shuffle Boil", "id"=>"d5e1e9ee-76b2-42b5-ad86-cafa133d5f8d", "duration"=>"349333"}, {"title"=>"Time for Change", "id"=>"37bb2d1a-377f-445a-bb6b-3f5fc40b4b8d", "duration"=>"254186"}, {"title"=>"The Present", "id"=>"b53277db-d88e-49fd-97fb-d72f7c1af87b", "duration"=>"317200"}, {"title"=>"Battle in a Box", "id"=>"9b18005e-52bc-45e0-9f17-79bf58cc21ed", "duration"=>"250000"}, {"title"=>"Out of This World", "id"=>"845343ec-4610-49bb-b9bd-bcf8417bfe0d", "duration"=>"287600"}, {"title"=>"Don't Axe Me", "id"=>"63e927c5-2006-4ab1-8a1d-73fd00910193", "duration"=>"277680"}, {"title"=>"Uno", "id"=>"78e88c75-2e85-4926-bbf2-504945fdf911", "duration"=>"388480"}, {"title"=>"Jungle Hard Bop", "id"=>"5c2cec2b-5320-4132-81c8-ced17e8978f2", "duration"=>"318040"}, {"title"=>"Blues in the Background", "id"=>"e40a1237-cffb-4bf3-a0aa-680cd3135f75", "duration"=>"199293"}]}}, "xmlns"=>"http://musicbrainz.org/ns/mmd-1.0#"}}

