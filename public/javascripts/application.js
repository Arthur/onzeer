var covers_path = "cover_files";
var tracks_path = "audio_files";
var database = null;
var r = null;
var tracks = null;

var will_play_id = null;
var playing_track_id = null;

function playNow(id, auto) {
  if (auto === undefined) { auto = true; }
  will_play_id = id;
  playing_track_id = id;
  var player = $('#player');
  var track_element = $('#'+id);
  var track = $.data(track_element.get(0), 'track');

  var info = player.find('.info');
  var img = player.find('.img');
  var play_pause = player.find('.play_pause');

  // safari don't seem to like reusing and <audio> by changin it's source, so we built a new one.
  $('audio').each(function(){ this.pause(); });
  $('audio').remove();

  $('#player .control').removeClass('disabled');

  var audio_src = prefix + tracks_path + '/' + id.substring(0,2) + '/' + id.substring(2,4) + '/' + id.substring(4)  + '.' + track.format;
  var audio = $('<audio> <source src="'+ audio_src + '" /></audio>').appendTo(player);

  $('.tracks li.playing').removeClass('playing');
  if (auto) { 
    audio.get(0).play();
    play_pause.removeClass('stopped');
    play_pause.addClass('playing');
    play_pause.find('span').text('pause');
    // set the class playing on the current track_li
    track_element.addClass('playing');
  }
  // audio.get(0).volume = 0.1;
  audio.bind("ended", trackEnded);

  setTimeout(function(){ $('#time_bar').trigger("showCurrentTime"); }, 100);

  // window.location.hash = '#' + track.id; // => scroll to the track html id ;-()

  info.html(track_info(track));
  img.html(track_img(track));
}

function trackEnded() {
  var just_played_id = $('.tracks li.playing').attr('id');
  playNext();
  $.post(prefix + 'tracks/' + just_played_id + '/just_listened', {});
}

function playNext() {
  playNow($('li.playing').next().attr('id'));
}
function playPrev() {
  playNow($('li.playing').prev().attr('id'));
}

function togglePlayPause() {
  var play_pause = $('#player .play_pause');
  var track_li = $('#'+playing_track_id);
  if (play_pause.hasClass('playing')) {
    $('audio').each(function(){ this.pause(); });
    track_li.removeClass("playing");
    play_pause.removeClass('playing');
    play_pause.addClass('stopped');
    play_pause.find('span').text('play');
  } else {
    $('audio').each(function(){ this.pause(); });
    var audio = $('#player audio');
    if (audio.length == 1) {
      audio.get(0).play();
      track_li.addClass("playing");
      play_pause.removeClass('stopped');
      play_pause.addClass('playing');
      play_pause.find('span').text('pause');
    }
  }
}

var timeout = null;

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
    setTimeout(function(){time_bar.trigger("showCurrentTime"); }, 1000);
  }
};

//html builders :
function track_img(track) {
  if (!(track.cover === undefined) && (track.cover != "undefined")) {
    var img_src = prefix + covers_path + '/' + track.cover.substring(0,2) + '/' + track.cover.substring(2,4) + '/' + track.cover.substring(4)  + '.png';
    return '<img src="' + img_src + '" />';
  } else if (track.asin){
    return '<img src="http://ec1.images-amazon.com/images/P/'+ track.asin + '.01.MZZZZZZZ.jpg" alt="?" />';
  } else{
    return '<img src="'+ prefix + 'images/unknow_cover.png" alt="?" />';
  };
  return undefined;
}

function track_info(track) {
  return '' +
    '<p>'+
    '<span class="artist">' + track.artist + '</span>' + ' / ' + 
    '<span class="album">' + track.album_name + '</span>' +
    '</p>'+
    '<p>'+
    '<span class="name">' + track.title + '</span>' +
    '</p>';
}

function track_li(track) {
  return $( '<li id="'+track.id+'">' +
    '<p class="control"/>' + 
    '<p class="artist">' + track.artist + '</p>' + 
    '<p class="album">' + track.album + '</p>' +
    '<p class="track_nb">'+ (track.track_nb > 9 ? '' : '0') + track.track_nb + '</p>' +
    '<p class="name">' + track.title + '</p>' +
    '<p class="duration">'+ format_seconds(track.seconds) + '</p>' +
    "</li>");
};

function player_div() {
  var player = $('#player');
  if (player.length == 0 ) { return null; }

  $('<div class="control disabled"/>').
    append('<div class="prev"><span>prev</span></div>').
    append('<div class="play_pause stopped"><span>play</span></div>').
    append('<div class="next"><span>next</span></div>').
    appendTo(player);
  var info_box = $('<div class="info_box" />');
  $('<div class="info" />').appendTo(info_box);
  $('<div class="img" />').appendTo(info_box);
  var duration = $('<div class="duration"></div>').appendTo(info_box);
  $('<div id="current_time" />').appendTo(duration);
  $('<div id="time_bar" />').append('<div/>').appendTo(duration);
  info_box.appendTo(player);

  return player;
}

function setupPlayer(tracks) {
  var player = player_div();

  if ($('.tracks.playable').length > 0) {
    var asin = null;
    if ($('.album .amazon').length > 0) {
      asin = $('.album .amazon').get(0).className.match(/asin_(\w+)/)[1];
    }
    for (var i = 0; i < tracks.length; i++) {
      track = tracks[i];
      track.asin = asin;
      var track_li = $('#'+track.id);
      $.data(track_li.get(0),'track', track);
      track_li.append('<span class="control"/>');
    }
    if (tracks.length > 0) { playNow(tracks[0].id, false); };
    $('.album .artist').hide();
    $('.album .album_name').hide();

    var time_bar = $('#time_bar');
    time_bar.bind("showCurrentTime",showCurrentTime);
    time_bar.click(function(event){
      var audio = $('audio').get(0);
      audio.currentTime = audio.duration * (event.clientX - time_bar.offset().left) / time_bar.width();
      showCurrentTime();
    });

    $('.tracks').click(function(event) {
      var target = $(event.target);
      if (target.hasClass("control")) {
        var track_li = target.parents('li');
        var id = track_li.attr('id');
        if (track_li.hasClass("playing")) {
          togglePlayPause();
          track_li.removeClass("playing");
        } else { playNow(id); };
      }
    });
  }

  // if (window.location.hash.length > 1) {
  //   var id = window.location.hash.substring(1);
  //   playNow(id);
  // }
  // setInterval(function() {
  //   if (window.location.hash.length > 1 && (window.location.hash.substring(1) != will_play_id)) {
  //     playNow( window.location.hash.substring(1) );
  //   }
  // }, 100);
  

  $('#player .prev').click(playPrev);
  $('#player .next').click(playNext);
  $('#player .play_pause').click(togglePlayPause);


  // Show / hide info

  $('.album .tracks').addClass('minimized');
  $('.album .tracks h3').click(function() { $('.album .tracks').toggleClass('minimized'); });

  $('.album .comments').addClass('minimized');
  $('.album .comments h3').live('click', function() { $('.album .comments').toggleClass('minimized'); });

  // Ajax for voting
  function display_votes() {
    var lovers_count = parseInt($('.album .votes .lovers').text(), 10);
    var haters_count = parseInt($('.album .votes .haters').text(), 10);
    var total = lovers_count + haters_count;
    if (total > 0) {
      $('.album .votes').removeClass('empty');
      $('.album .votes .lovers').css('width', 10+lovers_count*100/total + 'px');
      $('.album .votes .haters').css('width', 10+haters_count*100/total + 'px');
    } else {
      $('.album .votes').addClass('empty');
      $('.album .votes .lovers h4').text('+');
      $('.album .votes .haters h4').text('-');
    }
  }
  display_votes();
  $('.album .votes li').live('click', function(event) {
    var form = $(this).find('form');
    $.post(form.attr('action'), form.serialize(), function (data) {
      console.log(data);
      $('.votes').replaceWith(data);
      display_votes();
    });
    return false;
  });

  // Ajax for comments edition
  $('.album .comments .edit a').live('click', function(event) {
    var a = $(this);
    $.get(a.attr('href'), function (data) {
      a.parents('li').html($('.album form', data).get(0));
      $('.album form input[type="text"]').focus();
    });
    return false;
  });

  $('.album .comments .new a').live('click', function(event) {
    var a = $(this);
    $.get(a.attr('href'), function (data) {
      console.log($('.album form', data).get(0))
      a.parent('li').html($('.album form', data).get(0));
      $('.album form input[type="text"]').focus();
    });
    return false;
  });

  $('.album .comments input[type="submit"]').live('click', function(event) {
    var form = $(this).parents('form');
    $.post(form.attr('action'), form.serialize(), function (data) {
      $('.comments').replaceWith(data);
    });
    return false;
  });

}

$(document).ready(function() {
  if (tracks) {
    setupPlayer(tracks);
  }

  $('.cover_album').live('click', function (e) {
    var target = $(this);
    var url = target.find('a').attr('href') + '.json';
    $.getJSON(url, function(json) {
      $('#player').remove();
      $('.album').remove();
      $('body').prepend(json.view);
      setupPlayer(json.tracks);
    });
    e.stopPropagation();
  });

  $(document).keypress(function (e) {
    if (e.altKey || e.ctrlKey || e.metaKey) { return; }
    if (e.target.tagName == "INPUT" || e.target.tagName == "TEXTAREA") { return ;}
    if (e.which == 32 || (65 <= e.which && e.which <= 65 + 25) || (97 <= e.which && e.which <= 97 + 25)) {
      if ( ' ' == String.fromCharCode(e.which) ) { togglePlayPause(); return false; }
      if ( 'p' == String.fromCharCode(e.which) ) { playPrev(); }
      if ( 'n' == String.fromCharCode(e.which) ) { playNext(); }
    }
  });

  $('.albums_group .links li, .albums_group .links li a').live('click', function(e) {
    e.preventDefault();
    var target = $(this);
    var url = target.attr('href') || target.find('a').attr('href');
    target.parents('.albums_group').load(url);
  });

});


jQuery.ajaxSetup({ 
  'beforeSend': function(xhr) {xhr.setRequestHeader("Accept", "text/javascript")} 
});
