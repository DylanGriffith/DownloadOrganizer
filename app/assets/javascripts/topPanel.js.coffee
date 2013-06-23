DownloadOrganizer.TopPanelView = Backbone.View.extend
  initialize: ->
    if /files/.test(window.location.pathname)
      $('#files').addClass('active')
      $('#settings').addClass('active')
