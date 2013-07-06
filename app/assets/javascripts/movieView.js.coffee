DownloadOrganizer.MovieView = Backbone.View.extend
  tagName: 'div'
  className: 'movie'

  initialize:(options) ->
    @data = options

  render: ->
    @$el.html _.template @templateShow(), @data

  templateShow: ->
    $('#movie_show_template').html()

  templateEdit: ->
