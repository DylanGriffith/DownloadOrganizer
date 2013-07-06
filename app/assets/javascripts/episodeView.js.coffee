DownloadOrganizer.EpisodeView = Backbone.View.extend
  tagName: 'div'
  className: 'episode'

  initialize:(options) ->
    @data = options

  render: ->
    @$el.html _.template @templateShow(), @data

  templateShow: ->
    $('#episode_show_template').html()

  templateEdit: ->
