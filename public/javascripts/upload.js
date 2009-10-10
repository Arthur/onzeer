/** 
* based on : basic Safari 4 multiple upload example
* from  Andrea Giammarchi
* see http://webreflection.blogspot.com/2009/03/safari-4-multiple-upload-with-progress.html
*/

$(function() { 

    function size(bytes){   // simple function to show a friendly size
        var i = 0;
        while(1023 < bytes){
            bytes /= 1024;
            ++i;
        };
        return  i ? bytes.toFixed(2) + ["", " Kb", " Mb", " Gb", " Tb"][i] : bytes + " bytes";
    };

    $('input[type="file"]').attr("multiple","true");
    var input_name = $('input[type="file"]').attr("name")
    var input = $('input[type="file"]').get(0);
    
    $('form').submit(function(event){
      event.preventDefault();
      event.stopPropagation();
    
      var status = $('<div class="status"/>');
      $('#content').append(status);
    
      sendMultipleFiles({
        url: prefix + 'tracks',
        input_name: input_name,
        files: input.files,
        onloadstart: function(){ console.log(['start uploading', this]); },
        onprogress: function(rpe) { 
          // console.log(["progress", rpe, rpe.loaded, this.file.fileName, this.sent, this]);
          status.text("Uploading: " + this.file.fileName + 
          "  Sent: " + size(rpe.loaded) + " of " + size(rpe.total) + 
          "  Total Sent: " + size(this.sent + rpe.loaded) + " of " + size(this.total) );
        },
        onload: function(rpe, xhr){ console.log(["load", rpe, xhr]); },
        onerror: function() { console.log(["error", this]); }
      });

    });

});
