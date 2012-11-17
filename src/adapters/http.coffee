# Based on the gist: https://gist.github.com/1371892

http = require 'http'
url = require 'url'
Robot = require '../robot'
Adapter = require '../adapter'
{TextMessage} = require '../message'

class Http extends Adapter
  
  send: (user, strings...) ->
    str = strings[0].split('\n').join('<br />')
    @response.end "<html>
      <head>
        <title>Hubot on Azure</title>
        <style>
          body {font-family: helvetica, arial, san-serif;}
        </style>
      </head>
      <body>
        <h1>Hubot says:</h1>
        <div>
          #{str}
        </div>
      </body>"
      
  reply: (user, strings...) ->
    strings = strings.map (s) -> "#{user.name}: #{s}"
    @send user, strings...
      
  onRequest: (request, response) =>
    console.log "onRequest"
    @response = response
    request.setEncoding('utf8')
  
    url_parts = url.parse request.url, true

    if !url_parts.query.message?
      response.end '<html>
      <head><title>Hubot on Azure</title></head>
      <body>
        <h1>Welcome to Hubot on Azure!</h1>
        <p>Enter commands in the query string</p>
        <p>For example: ?message=hubot+help</p>
      </body>'
      return

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

    user = @userForId '1', name: 'Http', room: 'Http'
    
    server = http.createServer @onRequest
    port = process.env.PORT || 1337
    server.listen port
    console.log "Server running at http://0.0.0.0:#{port}"
   
    self.emit "connected"

exports.use = (robot) ->
  new Http robot