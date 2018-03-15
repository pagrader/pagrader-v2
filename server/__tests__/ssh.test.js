/**
 * This is to help test SSH connection locally (Not with travisCI)
 */
import { connect, command, transfer, runScript, getFile } from '../actions/ssh';
import { getSSHConnection, closeSSHConnection } from '../ssh/connection';
import mongoose from 'mongoose';
import secrets from '../config/secrets';
import path from 'path';
import fs from 'fs';

// These can only be ran if we have an ssh server to run the tests on
describe('SSH Protocols', () => {
  beforeAll(done => {
    mongoose.connect(secrets.db, dbErr => {
      if (dbErr) {
        done(dbErr);
      } else {
        for (const collection in mongoose.connection.collections) {
          if (mongoose.connection.collections[collection]) {
            mongoose.connection.collections[collection].remove(() => {});
          }
        }
        done();
      }
    });
  });

  const SOCKET_ID = 'mockSocketId';
  afterAll(done => {
    // Clean up after finished with tests
    closeSSHConnection(SOCKET_ID);
    mongoose.disconnect();
    done();
  });

  const SSH_INFO = {
    socketId: SOCKET_ID,
    username: secrets.sshTestInfo.split(':')[0],
    password: secrets.sshTestInfo.split(':')[1]
  };
  test('should return directory', () => {
    return expect(
      connect({
        body: SSH_INFO
      }).then(() => {
        const conn = getSSHConnection(SOCKET_ID);
        expect(conn).not.toBe(undefined);
        return command({
          body: {
            socketId: SOCKET_ID,
            command: 'ls -d */'
          }
        });
      })
    ).resolves.toBeDefined();
  });

  test('should transfer file', () => {
    const dirPath = path.join(__dirname, `../actions/repo/scripts/c_script.sh`);
    const fileStream = fs.createReadStream(dirPath);
    return expect(
      transfer({
        body: {
          socketId: SOCKET_ID,
          filePath: '.private_repo/c_script.sh',
          fileStream
        }
      })
    ).resolves.toBe(undefined);
  });

  test('should transfer PA1', () => {
    const dirPath = path.join(__dirname, `./PA1/PA1.prt`);
    const fileStream = fs.createReadStream(dirPath);
    return expect(
      transfer({
        body: {
          socketId: SOCKET_ID,
          filePath: './GRADER/PA1/PA1.prt',
          fileStream
        }
      })
    ).resolves.toBe(undefined);
  });

  test('should transfer cs7uaaP1.c', () => {
    const dirPath = path.join(__dirname, `./PA1/cs7u2_PA1/cs7uaaP1.c`);
    const fileStream = fs.createReadStream(dirPath);
    return expect(
      transfer({
        body: {
          socketId: SOCKET_ID,
          filePath: './GRADER/PA1/cs7u2_PA1/cs7uaaP1.c',
          fileStream
        }
      })
    ).resolves.toBe(undefined);
  });

  test('should transfer cs7uacP1.c', () => {
    const dirPath = path.join(__dirname, `./PA1/cs7u2_PA1/cs7uacP1.c`);
    const fileStream = fs.createReadStream(dirPath);
    return expect(
      transfer({
        body: {
          socketId: SOCKET_ID,
          filePath: './GRADER/PA1/cs7u2_PA1/cs7uacP1.c',
          fileStream
        }
      })
    ).resolves.toBe(undefined);
  });

  test('should transfer content', () => {
    return expect(
      transfer({
        body: {
          socketId: SOCKET_ID,
          filePath: '.private_repo/test.txt',
          content: 'This\nis\na\ntest\ntransfer.'
        }
      })
    ).resolves.toBe(undefined);
  });

  const MOCK_ASSIGNMENT = {
    repo: 'cs7s10',
    input: 'B\n1900\n3.3\n \nA\n2000\n2.2',
    name: 'PA1',
    bonusDate: 'Jul 2 15:00'
  };
  test('should run script', () => {
    return expect(
      command({
        body: {
          socketId: SOCKET_ID,
          command: 'rm .private_repo/test.txt; pwd'
        }
      }).then(absolutePath => {
        MOCK_ASSIGNMENT.path = `${absolutePath}/GRADER/PA1`;
        return runScript({
          body: {
            socketId: SOCKET_ID,
            assignment: MOCK_ASSIGNMENT
          }
        });
      })
    ).resolves.toBeDefined();
  });

  test('Output should contain 80 character limit message', done => {
    getFile({}, [
      SOCKET_ID,
      MOCK_ASSIGNMENT.name,
      'cs7u2_PA1',
      'cs7uaa.out.html'
    ])
      .then(res => {
        const readStream = res(process.stdout);
        readStream.on('data', data => {
          expect(data + '').toContain('There are 4 lines over 80 characters');
        });
        readStream.on('end', () => {
          done();
        });
      })
      .catch(done);
  });
});
