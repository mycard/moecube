path = require 'path'
raw = require('nw_raw-socket')
WebSocketClient = require("nw_websocket").client

puncher = null
socket = null
punching = {}
_connection = null

listen = (port, url, callback)->
  _connection.close() if _connection
  client = new WebSocketClient()
  client.on "connectFailed", (error) ->
    console.log "Connect Error: " + error.toString()
    return

  client.on "connect", (connection) ->
    _connection = connection
    console.log "正在分配端口"
    connection.on "error", (error) ->
      console.log error

    connection.on "close", ->
      console.log "连接关闭"

    connection.on "message", (message) ->
      console.log message.utf8Data
      if message.type is "utf8"
        [operator, operation] = message.utf8Data.split(' ', 2)
        switch operator
          when 'LISTEN'
            console.log "公网IP和端口: #{operation}"
            callback operation
          when 'PUNCH'
            [remote_address, remote_port] = operation.split(':')
            remote_port = parseInt remote_port
            puncher(port, remote_port, remote_address, socket)
            punching[operation] = setInterval ->
              puncher(port, remote_port, remote_address, socket)
            , 100
          when 'PUNCHOK'
            clearInterval punching[operation]
            delete punching[operation]
          else
            throw 'unknown message'
  console.log "正在连接服务器"
  client.connect url, "shinkirou"

exports.listen = (port, url, callback)->

  if puncher
    listen(port, url, callback)
  else
    try
      #test if i can create raw socket
      socket = raw.createSocket
        protocol: raw.Protocol.UDP
      #success
      puncher = require './puncher'
      listen(port, url, callback)
    catch e
      #failed, need elevate
      #FUCK UAC.
      WebSocketServer = require('nw_websocket').server;
      http = require('http');
      server = http.createServer()

      server.listen 5281, '127.0.0.1', ()->
        wincmd = require('node-windows');
        wincmd.elevate "#{path.join('bin','node')} app/js/puncher.js", {}, (error, stdout, stderr)->
          callback false if error

      wsServer = new WebSocketServer
        httpServer: server,
        autoAcceptConnections: true

      wsServer.on 'connect', (connection)->
        listen(port, url, callback)
        puncher = (local_port, remote_port, remote_address)->
          connection.sendUTF "#{local_port} #{remote_port} #{remote_address}"

        connection.on 'close', (reasonCode, description)->
          callback false
          server.close()
          puncher = null