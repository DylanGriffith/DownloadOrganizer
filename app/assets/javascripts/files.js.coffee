# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

window.FilesManager = class FilesManager

  @filesDiv = ->
    document.getElementById('filesSection')

  @searchFiles = ->
    filesDiv = @filesDiv()
    filesDiv.innerHTML = ""

    # Loop over episodes

    # Loop over movies
    $.getJSON("show.json").done((json) ->

      epList = FilesManager.getEpisodeList(json.episode_matches)
      movList = FilesManager.getMovieList(json.movie_matches)

      epHeading = document.createElement("h2")
      epHeading.innerHTML = "Episodes"
      filesDiv.appendChild epHeading
      filesDiv.appendChild epList
      movHeading = document.createElement("h2")
      movHeading.innerHTML = "Movies"
      filesDiv.appendChild movHeading
      filesDiv.appendChild movList
      FilesManager.searchResult = json
      procLink = document.createElement("p")
      procLink.innerHTML = "<a class=\"pull-right btn btn-primary btn-large\" href=\"javascript:;\" onclick=\"FilesManager.processResult();\">Process Result</a>"
      filesDiv.appendChild procLink
      $(filesDiv).toggleClass "hide", false
    ).fail (jqxhr, textStatus, error) ->
      err = textStatus + ", " + error
      console.log "Request Failed: " + err

    false

  @getEpisodeList: (episode_matches) ->
    epList = document.createElement("ul")
    $.each episode_matches, ->
      episode = @final_match
      path = @file_path
      epElement = document.createElement("li")
      heading = document.createElement("b")
      heading.innerHTML = episode.title + " - Season " + episode.season + " - Episode " + episode.episode
      epElement.appendChild heading
      epChild = document.createElement("ul")
      inner = document.createElement("li")
      inner.innerHTML = path
      epChild.appendChild inner
      epElement.appendChild epChild
      epList.appendChild epElement
    return epList

  @getMovieList: (movie_matches) ->
    movList = document.createElement("ul")
    $.each movie_matches, ->
      movie = @final_match
      path = @file_path
      movElement = document.createElement("li")
      heading = document.createElement("b")
      heading.innerHTML = movie.title + " - " + movie.year
      heading.innerHTML += " - cd" + movie.cd_num  if movie.cd_num isnt 0
      movElement.appendChild heading
      movChild = document.createElement("ul")
      inner = document.createElement("li")
      inner.innerHTML = path
      movChild.appendChild inner
      movElement.appendChild movChild
      movList.appendChild movElement
    return movList

  @processResult = ->
    return  unless FilesManager.searchResult
    filesDiv = @filesDiv()
    $.ajax
      type: "POST"
      url: "/process/execute"
      data: JSON.stringify(FilesManager.searchResult)
      dataType: "json"
      contentType: "application/json"
      success: (data) ->
        filesDiv.innerHTML = '<div class="alert alert-success"><strong>Complete</strong></div>'
        @searchResult = false
      error: (errMsg) ->
        filesDiv.innerHTML = '<div class="alert alert-error"><strong>Failed</strong></div>' + filesDiv.innerHTML

  @searchResult = false
