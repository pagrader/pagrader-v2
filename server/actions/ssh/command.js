import { getSSHConnection } from '../../ssh/connection';

export default function connect(req) {
  return new Promise((resolve, reject) => {
    const { socketId, command } = req.body;
    console.log('Executing Command:', command);
    const conn = getSSHConnection(socketId);
    if (conn) {
      conn.exec(command, (err, stream) => {
        if (err) {
          return reject({
            message: err
          });
        }

        let output = '';
        stream
          .on('close', () => {
            resolve(output.trim());
          })
          .on('data', data => {
            output += data;
            console.log('STDOUT:' + data);
          })
          .stderr.on('data', function(data) {
            console.log('STDERR:' + data);
          });
      });
    } else {
      return reject({
        message: 'No SSH Connection! Try relogging.'
      });
    }
  });
}
