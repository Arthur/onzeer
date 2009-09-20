var tracks_path = "/audio_files"
var database = null;
var r = null;

function executeSql(sql, args, callback) {
  if (!database) { return null; }
  database.transaction(function(tx) {
    tx.executeSql(sql, args, 
      function(tx, result) {
        r= result; 
        if (callback) { callback(result); }
      },
      function(tx, error) { console.log(error);}
    );
  });
}

function initDatabase(){
  database = openDatabase("Tracks", "1.0");
  var sql = "CREATE TABLE IF NOT EXISTS tracks (id TEXT UNIQUE, artist TEXT, album TEXT, album_id TEXT, track_nb REAL, title TEXT, extension TEXT, cover TEXT, seconds REAL)";
  executeSql(sql, []);
  var sql = "CREATE TABLE IF NOT EXISTS imports (id REAL UNIQUE, date TEXT)";
  executeSql(sql, []);
}

function resetDatabase(){
  executeSql("DROP TABLE tracks");
  executeSql("DROP TABLE imports");
}

function insertTrack(track) {
  var sql = "UPDATE tracks SET artist = ?, album = ?, album_id = ?, title = ?, extension = ?, cover = ?, track_nb = ?, seconds = ? WHERE id = ?"
  executeSql(sql, [track.artist, track.album_name, track.album_id, track.title, track.extension, track.cover, track.nb, track.seconds, track.id])
  
  var sql = "INSERT INTO tracks (id, artist, album, album_id, title, extension, cover, track_nb, seconds) VALUES (?,?,?,?,?,?,?,?,?)";
  executeSql(sql, [track.id, track.artist, track.album_name, track.album_id, track.title, track.extension, track.cover, track.nb, track.seconds])
}

function checkForTracks() {
  executeSql("SELECT * from imports ORDER BY id DESC LIMIT 1", [], function(result) {
    
    var url = "/tracks.json"
    var next = 1;
    if (result.rows.length == 1) {
      url += "?since="+ result.rows.item(0).date;
    }

    $.getJSON(url, null, function(json) {
      executeSql("INSERT INTO imports (date) VALUES (?)", [json.date]);
      $.each(json.tracks, function() {
        insertTrack(this);
      });
      if (json.tracks.length > 0) {
        buildArtistList();
        checkForTracks();
      }
    })
  });
  
}

function playNow(id) {

  var player = $('#player');
  executeSql("SELECT * from tracks WHERE id = ?", [id], function(result) {
    if (result.rows.length == 1) {
      var track = result.rows.item(0);

      // set the class playing on the current track_li
      $('.tracks li.playing').removeClass('playing');
      $('#'+id).addClass('playing');

      var info = player.find('.info');
      var img = player.find('.img');
      var play_pause = player.find('.play_pause');

      play_pause.removeClass('stopped');
      play_pause.addClass('playing');
      play_pause.text('pause');

      // safari don't seem to like reusing and <audio> by changin it's source, so we built a new one.
      $('audio').each(function(){this.pause()});
      $('audio').remove();

      var audio_src = tracks_path + '/' + id.substring(0,2) + '/' + id.substring(2,4) + '/' + id.substring(4)  + '.' + track.extension;
      var audio = $('<audio> <source src="'+ audio_src + '" /></audio>').appendTo(player);
      audio.get(0).play();

      audio.bind("ended", playNext);

      setTimeout(function(){$('#time_bar').trigger("showCurrentTime")}, 100);

      window.location.hash = '#' + track.artist + '/' + track.album + '/' + track.title;

      info.html(track_info(track));
      img.html(track_img(track));
    }
  });
}

function playNext() {
  playNow($('li.playing').next().attr('id'));
}
function playPrev() {
  playNow($('li.playing').prev().attr('id'));
}

function togglePlayPause() {
  var play_pause = $('#player .play_pause')
  if (play_pause.hasClass('playing')) {
    $('audio').each(function(){this.pause()});
    play_pause.removeClass('playing');
    play_pause.addClass('stopped');
    play_pause.text('play');
  } else {
    $('audio').each(function(){this.pause()});
    var audio = $('#player audio');
    if (audio.length == 1) {
      audio.get(0).play();
      play_pause.removeClass('stopped');
      play_pause.addClass('playing');
      play_pause.text('pause');
    }
  }
}

var last_search = null;
var timeout = null;

function checkNewSearch(){
  if (timeout) clearTimeout(timeout);
  timeout = setTimeout(function() {
    if ($('#player input').get(0).value != last_search) { buildArtistList(); }
  }, 200);
}

function buildArtistList(artist_and_album) {
  if (artist_and_album === undefined) { artist_and_album = []; }

  var artists_ul = $('ul.artists')
  var albums_ul = $('ul.albums');
  var tracks_ul = $('ul.tracks');
  var last_artist, last_album_id = null;
  var current_album_ul = null;

  var sql = "SELECT * from tracks";
  if (artist_and_album.length > 0) { sql += " WHERE artist = ?"; artists_ul = null; }
  if (artist_and_album.length > 1) { sql += " AND album = ?"; albums_ul = null; }

  var search = $('#player input').get(0).value;
  last_search = search
  if (search) {
    if (artist_and_album.length == 0) {
      sql += " WHERE artist LIKE ? OR album LIKE ? OR title LIKE ?";
      artist_and_album.push('%'+search+'%');
      artist_and_album.push('%'+search+'%');
      artist_and_album.push('%'+search+'%');
    } else if (artist_and_album.length == 1) {
      sql += " AND album LIKE ? OR title LIKE ?";
      artist_and_album.push('%'+search+'%');
      artist_and_album.push('%'+search+'%');
    } else {
      sql += " AND title LIKE ?";
      artist_and_album.push('%'+search+'%');
    }
  }
  // sql += " GROUP BY album"
  sql += " ORDER BY artist, album, track_nb"

  if (artists_ul) { artists_ul.html(""); }
  if (albums_ul) { albums_ul.html(""); }
  tracks_ul.html("");

  var time = Date.now();
  var old_time = null;

  executeSql(sql, artist_and_album, function(result) {
    if (artists_ul) { $('<li class="all selected">all</li>').appendTo(artists_ul) };
    if (albums_ul) { $('<li class="all selected">all</li>').appendTo(albums_ul) };

    // console.log(result.rows.length + " results");
    // old_time = time; time = Date.now(); console.log("sql result in " + (time-old_time));
    
    for ( var i = 0; i < result.rows.length; i++) {
      var track = result.rows.item(i);

      if (track.artist != last_artist) {
        last_artist = track.artist;
        if (artists_ul) { $("<li>"+last_artist+"</li>").appendTo(artists_ul) };
      }
      if (track.album_id != last_album_id) {
        last_album_id = track.album_id;
        if (albums_ul) { $("<li>"+
          '<span class="album">'+track.album+'</span>'+
          '<span class="artist" style="display:none;">'+track.artist+'</span>'+
          "</li>").appendTo(albums_ul); }
      }
    }

    // old_time = time; time = Date.now(); console.log("quick browser view in " + (time-old_time));

    var limit_albums_shown = 2000;
    var albums_shown_count = 0;

    last_album_id = null;

    for ( var i = 0; i < result.rows.length; i++) {
      var track = result.rows.item(i);

      if (track.album_id != last_album_id) {
        last_album_id = track.album_id;
        albums_shown_count += 1;
        if (albums_shown_count < limit_albums_shown) {
          var li = $('<li/>').appendTo(tracks_ul);
          $('<div class="album_info"/>').append('<p class="artist">' + track.artist + '</p>').
            append('<p class="album">' + track.album + '</p>').
            append($('<div class="img"/>').append(track_img(track))).appendTo(li);

          current_album_ul = $('<ul class="tracks_in_album"/>').appendTo(li);
        }
      }
      track_li(track).appendTo(current_album_ul);
    }
    // old_time = time; time = Date.now(); console.log("albums view in " + (time-old_time));
  });
}

function format_seconds(seconds) {
  var min = Math.floor(seconds / 60);
  var sec = Math.floor(seconds - min * 60);
  return '' + min + ':' + (sec > 9 ? '' : '0') + sec;
}

function showCurrentTime() {
  var time_bar = $('#time_bar');
  var current = Math.floor($('audio').get(0).currentTime);
  var duration = Math.floor($('audio').get(0).duration);
  $('#current_time').html( format_seconds(current) + ' / ' + format_seconds(duration));
  $('#time_bar div').css('width', current*100/duration + '%');
  if (!$.data(time_bar, 'timeoutSet')) {
    $.data(time_bar, 'timeoutSet',1);
    setTimeout(function(){time_bar.trigger("showCurrentTime")}, 1000);
  }
};

//html builders :
function track_img(track) {
  if (track.cover) {
    var img_src = tracks_path + '/' + track.cover.substring(0,2) + '/' + track.cover.substring(2,4) + '/' + track.cover.substring(4)  + '.png';
    return '<img src="' + img_src + '" />';
  } else {
    return '<img src="images/unknow_cover.png" alt="?">';
  };
}

function track_info(track) {
  return '' +
    '<span class="artist">' + track.artist + '</span>' + ' / ' + 
    '<span class="album">' + track.album + '</span>' + ' / ' +
    '<span class="name">' + track.title + '</span>';
}

function track_li(track) {
  return $( '<li id="'+track.id+'">' +
    '<p class="artist">' + track.artist + '</p>' + 
    '<p class="album">' + track.album + '</p>' +
    '<p class="track_nb">'+ (track.track_nb > 9 ? '' : '0') + track.track_nb + '</p>' +
    '<p class="name">' + track.title + '</p>' +
    '<p class="duration">'+ format_seconds(track.seconds) + '</p>' +
    "</li>");
};

function player_div() {
  var player = $('#player');
  if (player.length == 0 ) { player = null; return }

  $('<div class="control"/>').
    append('<div class="prev">prev</div>').
    append('<div class="play_pause stopped">play</div>').
    append('<div class="next">next</div>').
    appendTo(player);
  $('<div class="info" />').appendTo(player);
  $('<div class="img" />').appendTo(player);
  var duration = $('<div class="duration"></div>').appendTo(player);
  $('<div id="current_time" />').appendTo(duration);
  $('<div id="time_bar" />').append('<div/>').appendTo(duration);

  $('<div class="search" />').append('<input type="search"/>').appendTo(player);
  return player;
}

$(function() { 
  var content = $('#content')
  var player = player_div();

  initDatabase();

  checkForTracks();

  var browser = $("#browser");
  if (browser.length == 1) {
    var artists_ul = $("<ul class=\"artists\"></ul>").appendTo(browser);
    var albums_ul = $("<ul class=\"albums\"></ul>").appendTo(browser);
    var tracks_ul = $("<ul class=\"tracks\"></ul>").appendTo(browser);
  };

  if (window.location.hash.length > 1) {
    var parts = decodeURIComponent(window.location.hash.substring(1)).split('/');
    if (parts.length == 3) {
      executeSql("SELECT * from tracks WHERE artist = ? AND album = ? AND title = ?", parts, function(result){
        if (result.rows.length == 1) {
          playNow(result.rows.item(0).id)
        }
      })
    }
  }

  var time_bar = $('#time_bar');
  time_bar.bind("showCurrentTime",showCurrentTime);
  time_bar.click(function(event){
    var audio = $('audio').get(0);
    audio.currentTime = audio.duration * (event.clientX - time_bar.offset().left) / time_bar.width();
    showCurrentTime();
  });

  buildArtistList();

  artists_ul.click(function(event){
    var target = event.target
    if (target.tagName == "LI") {
      target = $(target);
      var artist = target.text();
      artists_ul.find('li').removeClass('selected');
      target.addClass('selected');
      if (target.hasClass('all')) { buildArtistList(); }
      else { buildArtistList([artist]); }
    }
  });

  albums_ul.click(function(event){
    var target = event.target;
    if (target.tagName == "SPAN") {
      target = $(target).parent('li');
    }
    target = $(target);
    var album = target.find('.album').text();
    var artist = target.find('.artist').text();

    albums_ul.find('li').removeClass('selected');
    target.addClass('selected');
    if (target.hasClass('all')) {
      artist = $('.artists .selected');
      if (artist.hasClass('all')) { buildArtistList([]); } else { buildArtistList([artist.text()]); }
    }
    else { buildArtistList([artist,album]); }
  });

  tracks_ul.dblclick(function(event) {
    var target = $(event.target);
    var id = target.attr('id');
    if (!id) { id = target.parents('li').attr('id'); }
    if (id) { playNow(id) };
  });

  player.find('.prev').click(playPrev);
  player.find('.next').click(playNext);
  player.find('.play_pause').click(togglePlayPause);

  $('#player input').keydown(checkNewSearch);
  $('#player input').click(checkNewSearch);

  $(document).keypress(function (e) {
    if (e.target.tagName == "INPUT") { return ;}
    if (e.which == 32 || (65 <= e.which && e.which <= 65 + 25) || (97 <= e.which && e.which <= 97 + 25)) {
      if ( ' ' == String.fromCharCode(e.which) ) { togglePlayPause(); return false; }
      if ( 'p' == String.fromCharCode(e.which) ) { playPrev() }
      if ( 'n' == String.fromCharCode(e.which) ) { playNext() }
    }
  })
});