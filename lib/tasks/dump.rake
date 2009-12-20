require 'mp3info'
def album_to_html(a)
  html = ""
  html << "<li>"
  html << "<a href=\"/albums/#{a.id}\">#{a.artist} #{a.name}</a>"
  if track = a.tracks.first
    html << "#{track.format}"
    html << "<pre>t = Track.find('#{track.id}'); i = Mp3Info.open(t.file);" if track.format == "mp3"
    html << "<pre>t = Track.find('#{track.id}'); i = MP4Info.open(t.file);" if track.format == "m4a"
    html << "<img src=\"#{track.public_cover_path}\" height=\"40\"/>" if track.cover
  end
  html << "</li>"
  html
end

task :dump => :environment do
  html = "<html><head><title>debug tracks covers</title></head>"
  html << "<body>"
  html << "<ul>"

  puts "********* m4a with cover..."
  Album.all.each do |a|
    next unless a.tracks.first.format.to_sym == :m4a && a.cover
    puts "#{a.artist} #{a.name}"
    html << album_to_html(a)
  end
  File.open(Rails.root.join('public','tracks_debug.html'),'w') { |f| f.write(html+"</ul></body></html>") }

  puts "********* m4a without cover..."
  Album.all.each do |a|
    next unless a.tracks.first.format.to_sym == :m4a && !a.cover
    puts "#{a.artist} #{a.name}"
    html << album_to_html(a)
  end
  File.open(Rails.root.join('public','tracks_debug.html'),'w') { |f| f.write(html+"</ul></body></html>") }

  puts "********* mp3 with cover..."
  Album.all.each do |a|
    next unless a.tracks.first.format.to_sym == :mp3 && a.cover
    puts "#{a.artist} #{a.name}"
    html << album_to_html(a)
  end
  File.open(Rails.root.join('public','tracks_debug.html'),'w') { |f| f.write(html+"</ul></body></html>") }

  puts "********* mp3 without cover..."
  Album.all.each do |a|
    next unless a.tracks.first.format.to_sym == :mp3 && !a.cover
    puts "#{a.artist} #{a.name}"
    html << album_to_html(a)
  end
  html << "</ul>"
  html << "</body>"
  html << "</html>"
  File.open(Rails.root.join('public','tracks_debug.html'),'w') { |f| f.write(html) }
end

task :dump_apic => :environment do
  Album.all.each do |a|
    track = a.tracks.first
    next unless track && track.format.to_sym == :mp3
    info = Mp3Info.open(track.file)
    next unless info.tag2["APIC"]
    puts "#{info.tag2['APIC'][0..30].inspect}   t = Track.find('#{track.id}'); i = Mp3Info.open(t.file); i.tag2.keys; test =i.tag2['APIC'][0..30]"
    puts 
  end
end

task :dump_pic => :environment do
  Album.all.each do |a|
    track = a.tracks.first
    next unless track && track.format.to_sym == :mp3
    info = Mp3Info.open(track.file)
    next unless info.tag2["PIC"]
    puts "#{info.tag2['PIC'][0..30].inspect}    t = Track.find('#{track.id}'); i = MP4Info.open(t.file);"
  end
end
