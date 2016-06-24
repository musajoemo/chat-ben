class @ChatAgain
  constructor: (options) ->
    @url = options.url
    window.chatAgain = =>
      postId = $('.post-header').data('post-id')
      binId = $('.bin-header').data('bin-id')
      url = "#{@url}/bins/#{binId}?post=#{postId}"
      window.location = url

    $('#chat-again').on 'click', window.chatAgain