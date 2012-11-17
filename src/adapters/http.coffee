# Based on the gist: https://gist.github.com/1371892

http = require 'http'
url = require 'url'
Robot = require '../robot'
Adapter = require '../adapter'
Events = require 'events'
{TextMessage} = require '../message'

class Http extends Adapter
  
  send: (user, strings...) ->
    console.log "in send!"
    str = strings.join "</br>"
    console.log str
    @response.end str
#    @eventEmitter.emit "botReply", str
      
  reply: (user, strings...) ->
    console.log "in reply!"
    strings = strings.map (s) -> "#{user.name}: #{s}"
    @send user, strings...
      
  onRequest: (request, response) =>
    console.log "onRequest"
    @response = response
    request.setEncoding('utf8')
  
    url_parts = url.parse request.url, true
    console.log "message: #{url_parts.query.message}"
    message = url_parts.query.message

    if message == "hubot die"
      @robot.shutdown()
      response.end 'Goodbye cruel world!'
      process.exit 0

    console.log "about to receive message"
    @receive new TextMessage @user, message

  run: ->
    self = @

    console.log "Hubot: the Shell."
    process.on 'uncaughtException', (err) =>
      @robot.logger.error err.stack

    eventEmitter = new Events.EventEmitter
    @eventEmitter = eventEmitter
    user = @userForId '1', name: 'Http', room: 'Http'
    
    server = http.createServer @onRequest
    port = process.env.PORT || 1337
    server.listen port
    console.log "Server running at http://0.0.0.0:#{port}"
   
    self.emit "connected"

exports.use = (robot) ->
  new Http robot