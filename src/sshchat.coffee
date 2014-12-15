Robot   = require('hubot').Robot
Adapter = require('hubot').Adapter
TextMessage = require('hubot').TextMessage
util = require('util')

SSHConnection = require('ssh2')
conn = new SSHConnection()

class SshchatAdapter extends Adapter

  send: (envelope, strings...) ->
    for string in strings
      strs = string.split "\n"
      for str in strs
        @sshStream.write str + "\r"

  reply: (envelope, strings...) ->
    for string in strings
      @send string

  run: ->
    self = @
    options =
      host: process.env.HUBOT_SSHCHAT_SERVER
      port: process.env.HUBOT_SSHCHAT_PORT
      username: process.env.HUBOT_SSHCHAT_USERNAME
      privateKey: require('fs').readFileSync(process.env.HUBOT_SSHCHAT_IDENTKEY)
    conn.connect options
    conn.on "ready", ->
      console.log "connected to ssh-chat!"
      conn.shell (err, stream) ->
        throw err if err
        self.sshStream = stream
        self.emit "connected"
        stream.on 'data', (data) ->
          data = data + ""
          data = data.substring 0, data.length - 2
          splitdata = data.split("\u001b[")
          newdata = []
          splitdata.forEach (v, k) ->
            if k == 0
              newdata.push v
            else
              newsection = v.split "m"
              newsection.shift()
              newdata.push(newsection.join "m")
          data = newdata.join ""

          if data != "[" + options.username && data != "" && data != "\u001b[D\u001b[D\u001b[D\u001b[D\u001b[D\u001b[D\u001b"
            console.log(">>" + data + "<<")
            data = data.trim()
            parts = data.split(" ")
            if parts.length
              if parts[0].indexOf(":") == -1
                return
              author = parts[0].replace(":", "")
              parts.shift()
              msg = parts.join " "
              user = self.robot.brain.userForId author, name: author, room: "main"
              if author != options.username
                self.receive new TextMessage(user, msg, 'messageId')
    

module.exports.use = (robot) ->
  new SshchatAdapter robot