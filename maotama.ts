import raw from 'raw-socket';

const socket = raw.createSocket({ protocol: raw.Protocol.UDP });

class Handler {
  static connect(local_port, remote_port, remote_address) {
    const buffer = new Buffer(9);
    buffer.writeUInt16BE(local_port, 0);
    buffer.writeUInt16BE(remote_port, 2);
    buffer.writeUInt16BE(buffer.length, 4);
    socket.send(buffer, 0, buffer.length, remote_address, (error, bytes) => {
    });
  };
}

process.on('message', (message) => Handler[message.method](...message.params));

process.on('disconnect', process.exit);

process.send!('initialized');
