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
        <script src='//ajax.googleapis.com/ajax/libs/jquery/1.8.3/jquery.min.js'></script>
        <script>
          $(function() {
            $('#hubot-form').submit(function() {
              $('#hubot-response').load('./?message=' + encodeURI($('#message').val()));
              return false;
            });
          });
        </script>
        <style>
          @font-face{
            font-family:'Segoe UI';src:local('Segoe UI'),url(//az213233.vo.msecnd.net/Content/2.8.00298.1.121115-0734/Fonts/segoeui.ttf)
          }
          @font-face{
            font-family:'Segoe UI Semibold';src:local('Segoe UI Semibold'),url(//az213233.vo.msecnd.net/Content/2.8.00298.1.121115-0734/Fonts/seguisb.ttf)
          }
          @font-face{
            font-family:'Segoe UI Light';src:local('Segoe UI Light'),url(//az213233.vo.msecnd.net/Content/2.8.00298.1.121115-0734/Fonts/segoeuil.ttf);
          }
          body {
            font-family: 'Segoe UI';
            color: #777;
          }
          h1 {
            font-family: 'Segoe UI Light';
            color: #999;
            margin-top: 10px;
          }
          h1 span.welcome {
            font-size: 1.5em;
            color: #222;
            padding-right: 10px;
          }
          h1 span.subtitle {
            font-size: 1.1em;
          }
          input {
            font-size: 2em;
            color: #333;
            padding: 4px 8px;
          }
          #main {
            width: 800px;
            margin: 0 auto;
            padding: 20px;
            color: #777;
          }
          p {
            padding: 0 5px;
          }
          #hubot-response {
            color: #333;
            font-size: 1.8em;
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

    @response.end "<h1>hubot says:</h1>
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
      response.end htmlTemplate.replace "{CONTENT}", '<h1><span class="welcome">hubot on azure</span> 
        <span class="subtitle">robots in <em>the cloud</em></span></h1>
        <p>
          Commands are passed using the query string using the format <code>?message=the+command</code>
        </p> 
        <p>
          ...or use the convenient form here to send a command.
        </p>
        <form id="hubot-form" method="get" href=".">
          <input id="message" type="text" name="message" />
          <input id="submit" type="submit" value="tell the robot" />
        </form>
        <p>For example: hubot help</p>
        <div id="hubot-response">&nbsp;</div>'
      return

    message = url_parts.query.message

    if message == "hubot die"
      console.log "shutting down hubot."
      @robot.shutdown()
      response.end '<h1>Goodbye cruel world!</h1>'
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