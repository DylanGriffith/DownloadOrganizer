DownloadOrganizer.DownloadManagerView = Backbone.View.extend

  events:
    'click #search-files' : 'searchFilesClick'
    'click #process-files' : 'processFilesClick'

  initialize: ->

  render: ->

  filesDiv: ->
    $('#files-section')

  searchFilesClick: (e) ->
    e.preventDefault()
    $.ajax
      type: 'GET'
      url: 'show.json'
      success: (data) => @handleSuccess(data)
      error: (data) => @handleFailure(data)

  processFilesClick: ->
    data = {}
    data.items_with_matches = @toBeDeleted()
    data.episode_matches = @episodesToProcess()
    data.movie_matches = @moviesToProcess()
    $.ajax
      type: "POST"
      url: "/process/execute"
      data: JSON.stringify(data)
      dataType: "json"
      contentType: "application/json"
      success: =>
        @filesDiv().innerHtml = @processSuccessMessage
      error: =>
        @filesDiv().innerHtml = @processFailureMessage + @filesDiv.innerHtml

  processSuccessMessage: ->
    '<div class="alert alert-success"><strong>Complete</strong></div>'

  processFailureMessage: ->
    '<div class="alert alert-error"><strong>Failed</strong></div>'

  toBeDeleted: ->
    toDelete = []
    section = $('#to-delete-section')
    section.children('.to-delete-item').each (key,item) ->
      if ($(item).find('.to-delete-checkbox').is(':checked'))
        toDelete.push $(item).find('.path').html()
    return toDelete

  episodesToProcess: ->
    episodes = []
    @episodeViews.map (episodeView) =>
      episodes.push episodeView.data
    return episodes

  moviesToProcess: ->
    movies = []
    @movieViews.map (movieView) =>
      movies.push movieView.data
    return movies

  handleSuccess: (data) ->
    @episodeViews = []
    @movieViews = []
    @filesDiv().toggleClass('hide',false)
    @filesDiv().html ""
    @matches = data

    @filesDiv().append @processButton()
    @filesDiv().append "<br/><br/>"
    @filesDiv().append @episodesRender()
    @filesDiv().append @moviesRender()
    @filesDiv().append @toDeleteRender()

  handleFailure: (data) ->
    alert('Failed to retrieve search results!')

  toDeleteSectionCreate: ->
    $("<div id=\"to-delete-section\"></div>")

  toDeleteRender: ->
    section = @toDeleteSectionCreate()
    section.append "<br/><h2> Downloads To Delete </h2>"
    @matches.items_with_matches.map (item) =>
      section.append _.template @torrentShowTemplate(), { path: item }
    return section

  moviesSectionCreate: ->
    $(document.createElement "div")

  moviesRender: ->
    section = @moviesSectionCreate()
    section.append '<br/><h2> Movies </h2>'
    @matches.movie_matches.map (item) =>
      movie = new DownloadOrganizer.MovieView(item)
      movie.render()
      section.append(movie.el)
      @movieViews.push movie
    return section

  episodesSectionCreate: ->
    $(document.createElement("div"))

  episodesRender: ->
    section = @episodesSectionCreate()
    section.append '<h2> Episodes </h2>'
    @matches.episode_matches.map (item) =>
      episode = new DownloadOrganizer.EpisodeView(item)
      episode.render()
      section.append(episode.el)
      @episodeViews.push episode
    return section

  processButton: ->
    "<div id=\"process-files\" class=\"pull-left btn btn-primary btn-large\">Process Result</a>"

  torrentShowTemplate: ->
    $('#torrent_show_template').html()
