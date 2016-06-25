#= require ./channels/room-channel

class @RoomShow
  constructor: (options) ->
    @nick = currentUser.name
    @room = options.room
    @mobile = options.mobile
    @signalServer = options.signalServer
    @_setStatusWithSwitch()
    @reacting = false

    @_bindDom()

  onReactMousedown: ->
    return unless forceSignIn(event)
    @reacting = true
    successCallback = (stream) =>
      options = { type: 'video', frameInterval: 20 }
      @reactStream = stream
      window.recordRTC = RecordRTC(stream, options)

      video = document.querySelector('#reaction-preview')
      if window.URL
        video.src = window.URL.createObjectURL(stream)
      else
        video.src = stream
      video.play()

      @mouseup = false
      @isHold = false
      @isTimeOut = false

      $('#reaction-preview').removeClass('display-none')
      $('.reactions-and-react-button').addClass('display-none')
      $('.reaction-panel').append('<div class="glow-container"><span class="red-glow"></span><h2> You Are Reacting!</h2></div>')
      recordRTC.startRecording()

      setTimeout(=>
        @isHold = !@mouseup
      , 1000)

      setTimeout(=>
        if !@isHold
          recordRTC.stopRecording @stopRecordingRTC
      , 4000)

      setTimeout(=>
        @isTimeOut = !@mouseup
        if @isTimeOut
          recordRTC.stopRecording @stopRecordingRTC
      , 10000)

    errorCallback = (error) =>
      @stopRecordingRTC()
      console.log 'navigator.getUserMedia error: ', error

    navigator.getUserMedia = navigator.getUserMedia || navigator.webkitGetUserMedia || navigator.mozGetUserMedia
    navigator.getUserMedia({ audio: true, video: true }, successCallback, errorCallback)

  stopRecordingRTC: (videoURL) =>
    @reacting = false
    @reactStream.getTracks()[0].stop() if @reactStream
    @reactStream.getTracks()[1].stop() if @reactStream
    $('.reaction-panel .glow-container').remove()
    $('.react-results-container').removeClass('display-none')
    $('.react-results-container').prepend("<video style=\"width:90%;\" autoplay=\"true\" src=\"#{videoURL}\"></video>") if videoURL
    $('#reaction-preview').addClass('display-none')

  removeVideo: (video, peer) =>
    remote = document.getElementById('remote')
    el = document.getElementById('container_' + @webrtc.getDomId(peer))
    if remote and el
      remote.removeChild el

    $('.control-buttons').addClass('hidden')
    $('.chat-again-container').removeClass('hidden')
    @_setStatus('ending')
    $('.remote-container').addClass('invisible')

    @stopWebRTC()

  showVolume: (el, volume) ->
    return unless el
    if volume < -45
      el.style.height = '0px'
    else if volume > -20
      el.style.height = '100%'
    else
      el.style.height = '' + Math.floor((volume + 100) * 100 / 25 - 220) + '%'

  _bindDom: ->
    window.onbeforeunload = =>
      if @status == 'waiting'
        $.ajax(url: "/chat/#{@room}", type: 'PUT') # When you leave your own room and navigate back to front page, you should see num chating change becauce of you.
        return undefined
      else if @status == 'chatting'
        return 'Make sure to end your conversation before leaving!'
      else
        return undefined

    $('#end-conversation').on 'click', =>
      @webrtc.leaveRoom()
      @webrtc.connection.disconnect()

    $('#next-post').on 'click', =>
      $('#next-post').tooltip('disable')

    $('button').on 'click', ->
      $(this).blur()

    $('#react-button').show()
    @setupRecordRTCDom()

    @_controlButtons()
    @_newPostButton()
    @_matchingSwitch()

  _setStatus: (status) ->
    @status = status
    window.status = status
    status = switch status
      when 'not-waiting'
        'Video Chat is disabled'
      when 'waiting'
        'Waiting for someone to chat with'
      when 'chatting'
        "You are chatting with #{@otherPeer.nick || 'someone'}"
      when 'ending'
        "Your conversation with #{@otherPeer.nick || 'somone'} has ended"
      else
        ""

    $('.status').text('')
    $('.status').append(document.createTextNode(status))

  _matchingSwitch: ->
    $('#myonoffswitch').change (event) =>
      window.matchingSwtich(event.target.checked)

      doSwitch = =>
        if @status == 'waiting' && !event.target.checked
          @_setStatus('not-waiting')
          @stopWebRTC()
        else if @status == 'not-waiting' && event.target.checked
          @_setStatus('waiting')
          @_startWebRTC()

      setTimeout(doSwitch, 700)

  _setStatusWithSwitch: ->
    if $('#myonoffswitch').is(':checked') && !@mobile
      @_setStatus('waiting')
      @_startWebRTC()
    else
      @_setStatus('not-waiting')
      $('#localVideo').addClass('invisible')

  stopWebRTC: ->
    $('#localVideo').addClass('invisible')
    @webrtc.leaveRoom()
    @webrtc.stopLocalVideo()

  _startWebRTC: ->
    $('#localVideo').removeClass('invisible')

    if @webrtc
      @webrtc.startLocalVideo()
    else
      @webrtc = new SimpleWebRTC
        localVideoEl: 'localVideo'
        remoteVideosEl: ''
        autoRequestMedia: true
        debug: false
        detectSpeakingEvents: true
        autoAdjustMic: false
        nick: @nick
        url: @signalServer

      @webrtc.on 'readyToCall', =>
        @webrtc.joinRoom @room

      @webrtc.on 'channelMessage', (peer, label, data) =>
        if data.type == 'volume'
          @showVolume document.getElementById('volume_' + peer.id), data.volume

      @webrtc.on 'videoAdded', (video, peer) =>
        @otherPeer = peer
        remote = document.getElementById('remote')
        if remote
          d = document.createElement('div')
          d.className = 'videoContainer remote'
          d.id = 'container_' + @webrtc.getDomId(peer)
          d.appendChild video
          vol = document.createElement('div')
          vol.id = 'volume_' + peer.id
          vol.className = 'volume_bar'

          d.appendChild vol
          remote.insertBefore d, remote.firstChild

        document.getElementById('notification-sound').play()

        $('.control-buttons').removeClass('invisible')
        $('.no-user-container').addClass('hidden')

        @_setStatus('chatting')

      @webrtc.on 'videoRemoved', (video, peer) =>
        @removeVideo(video, peer)

      @webrtc.on 'volumeChange', (volume, treshold) =>
        @showVolume document.getElementById('localVolume'), volume

  setupRecordRTCDom: ->
    $('#react-button').mousedown =>
      @onReactMousedown()

    $('#react-button').bind 'mouseup mouseleave', =>
      return unless forceSignIn(event)
      if @reactStream && @reacting
        @mouseup = true
        $('#react-button').addClass('display-none')
        if @isHold && !@isTimeOut
          recordRTC.stopRecording @stopRecordingRTC

    $('#post-reaction').click =>
      $('.react-results-container').addClass('display-none')
      $('.reactions-and-react-button').removeClass('display-none')
      $('#react-button').removeClass('display-none')
      fd = new FormData();
      fd.append('post_id', $('.post-header').data('post-id'));
      fd.append('video', recordRTC.getBlob());
      $.post
        url: "/reactions",
        data: fd,
        processData: false,
        contentType: false,
        success: (data) =>
          window.addReaction($('.post-header').data('post-id'))

    $('#toss-reaction').click ->
      $('#react-button').removeClass('display-none')
      $('.react-results-container').addClass('display-none')
      $('.reactions-and-react-button').removeClass('display-none')
      recordRTC.clearRecordedData()
      $('.react-results-container video').remove()

  _controlButtons: ->
    $('#mute-microphone-button').on 'click', @_toggleMic
    $('#mute-volume-button').on 'click', @_toggleVolume

  _newPostButton: ->
    $newForm = $("#new_post")
    $newForm.on "ajax:success", (e, data, status, xhr) ->
      newPost = new NewPost
      newPost.hideNewPost()
      postId = data.id
      binId = data.bin_id
      $("#guide-contents tr[data-guide-bin-id='#{binId}']").append("<td data-guide-post-id=\"#{postId}\"><button class=\"selected-show\"></button></td>")
      $('.selected-show').text(data.title)
      window.postFromGuide(binId: binId, postId: postId)

    $newForm.on "ajax:error", (e, xhr, status, error) ->
      newPost = new NewPost
      newPost.hideNewPost()

  _toggleMic: =>
    $mic = $('#mute-microphone-button')
    if $mic.hasClass('btn-danger')
      @webrtc.unmute()
      @_toggleDanger($mic)
    else
      @webrtc.mute()
      @_toggleDanger($mic)

  _toggleVolume: =>
    $vol = $('#mute-volume-button')
    if $vol.hasClass('btn-danger')
      @webrtc.setVolumeForAll(1)
      @_toggleDanger($vol)
    else
      @webrtc.setVolumeForAll(0)
      @_toggleDanger($vol)

  _toggleDanger: ($el) ->
    $el.toggleClass('btn-danger')
    $el.toggleClass('btn-default')
