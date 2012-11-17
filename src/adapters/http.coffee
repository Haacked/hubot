# Based on the gist: https://gist.github.com/1371892

http = require 'http'
url = require 'url'
Robot = require '../robot'
Adapter = require '../adapter'
{TextMessage} = require '../message'

class Http extends Adapter

  htmlTemplate = "<html>
      <head>
        <title>Hubot on Azure</title>
        <style>
          body {
            font-family: helvetica, arial, san-serif;
            background-color: #999;
          }
          h1 {
            color: #777;
            font-weight: normal;
            font-size: 1.2em;
            margin-top: 10px;
          }
          h1 span.welcome {
            color: #aaa;
            padding-right: 10px;
            font-size: 1.2em;
          }
          input {
            font-size: 2em;
            color: #666;
          }
          #main {
            width: 800px;
            margin: 0 auto;
            border: solid 4px;
            padding: 20px;
            background-color: #fff;
            color: #444;
          }
          p {
            padding: 0 10px;
          }
        </style>
      </head>
      <body>
        <div id='main'>
          {CONTENT}
        </div>
      </body>
      </html>"

  send: (user, strings...) ->
    str = strings[0].split('\n').join('<br />')

    if /\.(png|jpe?g|gif)/.test(str)
      str = "<img src='#{str}' width='600px' />";

    @response.end htmlTemplate.replace "{CONTENT}", "<h1>Hubot says:</h1>
        <div>
          #{str}
        </div>"
      
  reply: (user, strings...) ->
    strings = strings.map (s) -> "#{user.name}: #{s}"
    @send user, strings...
      
  onRequest: (request, response) =>
    @response = response
    request.setEncoding('utf8')
  
    url_parts = url.parse request.url, true

    if !url_parts.query.message?
      response.end htmlTemplate.replace "{CONTENT}", '<h1><span class="welcome">Hubot on Azure</span> 
        Robots have taken to the clouds.</h1>
        <p>
          Commands are passed using the query strings. 
          Use the convenient form here to post a command.
        </p>
        <form method="get" href=".">
          <input type="text" name="message" />
          <input type="submit" />
        </form>
        <p>For example: hubot help</p>'      
      return

    message = url_parts.query.message

    if message == "hubot die"
      console.log "shutting down hubot."
      @robot.shutdown()
      response.end htmlTemplate.replace "{CONTENT}", '<h1>Goodbye cruel world!</h1>'
      process.exit 0

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