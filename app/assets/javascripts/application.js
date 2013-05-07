// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
//= require jquery
//= require jquery_ujs
//= require_tree .
//

var searchResult = false;

function searchFiles() {
    var filesDiv = document.getElementById( 'filesSection' );
    filesDiv.innerHTML = "";
    $.getJSON( 'show.json' )
        .done( function (json) {
            // Loop over episodes
            epList = document.createElement( 'ul' );
            $.each( json.episode_matches , function( ) {
                var episode = this.final_match;
                var path = this.file_path;
                var epElement = document.createElement( 'li' );
                var heading = document.createElement( 'b' );
                heading.innerHTML = episode.title + ' - Season ' + episode.season + ' - Episode ' + episode.episode;
                epElement.appendChild( heading );
                var epChild = document.createElement( 'ul' );
                var inner = document.createElement( 'li' );
                inner.innerHTML = path;
                epChild.appendChild( inner );
                epElement.appendChild( epChild );
                epList.appendChild( epElement );
            });
            // Loop over movies
            movList = document.createElement( 'ul' );
            $.each( json.movie_matches , function( ) {
                var movie = this.final_match;
                var path = this.file_path;
                var movElement = document.createElement( 'li' );
                var heading = document.createElement( 'b' );
                heading.innerHTML = movie.title + " - " + movie.year;
                if ( movie.cd_num !== 0 ) {
                    heading.innerHTML += " - cd" + movie.cd_num;
                }
                movElement.appendChild( heading );
                var movChild = document.createElement( 'ul' );
                var inner = document.createElement( 'li' );
                inner.innerHTML = path;
                movChild.appendChild( inner );
                movElement.appendChild( movChild );
                movList.appendChild( movElement );
            });

            var epHeading = document.createElement( 'h2' );
            epHeading.innerHTML = "Episodes";
            filesDiv.appendChild( epHeading );
            filesDiv.appendChild( epList );

            var movHeading = document.createElement( 'h2' );
            movHeading.innerHTML = "Movies";
            filesDiv.appendChild( movHeading );
            filesDiv.appendChild( movList );

            searchResult = json;

            var procLink = document.createElement( 'p' );
            procLink.innerHTML = '<a href="javascript:;" onclick="processResult();">Process Result</a>';
            filesDiv.appendChild( procLink );

        })
    .fail(function( jqxhr, textStatus, error ) {
        var err = textStatus + ', ' + error;
        console.log( "Request Failed: " + err);
    });


    return false;
}

function processResult() {

    if ( !searchResult ){
        return;
    }

    $.ajax({
        type: "POST",
    url: "../process/execute",
    data: JSON.stringify( searchResult ),
    contentType: "application/json; charset=utf-8",
    dataType: "json",
    success: function(data){alert(data);},
    failure: function(errMsg) {
        alert(errMsg);
    }
    });

}
