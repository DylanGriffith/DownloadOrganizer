DownloadOrganizer.TopPanelView = Backbone.View.extend
  initialize: ->
    debugger
    if /files/.test(window.location.pathname)
      $('#files').addClass('active')
      $('#settings').addClass('active')
