socket = null
punch = (local_port, remote_port, remote_address, _socket)->
  if _socket
    socket = _socket
  else if !socket
    socket = raw.createSocket(protocol: raw.Protocol.UDP)
  buffer = new Buffer(9)
  buffer.writeUInt16BE(local_port, 0)
  buffer.writeUInt16BE(remote_port, 2)
  buffer.writeUInt16BE(buffer.length, 4)
  socket.send buffer, 0, buffer.length, remote_address, (error, bytes)->
    throw error if error

if require.main is module
  raw = require('raw-socket')
  WebSocketClient = require("websocket").client
  websocket = new WebSocketClient()
  websocket.connect "ws://127.0.0.1:5281/", "tunnel"
  websocket.on "connectFailed", (error) ->
    console.log  error
  websocket.on "connect", (connection) ->
    console.log connection
    connection.on "error", (error) ->
      console.log error
    connection.on "close", ->
      console.log 'closed'
    connection.on "message", (message) ->
      if message.type is "utf8"
        [local_port, remote_port, remote_address] = message.utf8Data.split(' ')
        punch parseInt(local_port), parseInt(remote_port), remote_address
else
  raw = require('nw_raw-socket')
  module.exports = punch