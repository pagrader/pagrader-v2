/**
 * This file helps transfer the input.txt needed and then runs the script in the hidden directory
 */
import { command, transfer } from './';
import { saveStudents } from '../grade';

// TODO: Need to split this file apart so that we make multiple queries

export default async function runScript(req) {
  const { assignment, socketId } = req.body;
  const { repo, input, path, bonusDate, name } = assignment;
  const repoPath = `.private_repo/${path.match(/.*\/(.+?)\/?$/)[1]}`;

  try {
    await removeProjectDirFromPrivateRepoIfItExist(repoPath, socketId);
    await transferFileContentToServer(socketId, input, `${repoPath}/input.txt`);
    await copyFilesToGradeToPrivateRepo(repoPath, path, socketId);
    const data = await getResultFromGradingScript(
      repoPath,
      bonusDate,
      socketId
    );
    const previewList = await getHTMLOutPutFileList(name, socketId);

    if (!data.graders || !previewList) {
      return Promise.reject({
        message:
          'Error running script! Please make sure repository path is correct!'
      });
    }

    const bonusList = await getBonusList(name, socketId);
    await saveStudentResults(data, previewList, repo, name, bonusList);

    return data;
  } catch (err) {
    console.log(err);
    return Promise.reject({ message: err });
  }
}

async function removeProjectDirFromPrivateRepoIfItExist(repoPath, socketId) {
  const bashCommand = `pwd;rm -r ${repoPath}`;
  return executeCommandInShell(socketId, bashCommand);
}

async function copyFilesToGradeToPrivateRepo(repoPath, path, socketId) {
  const bashCommand = `cd ${repoPath};pwd;
                   cp -r ${path}/* .;
                   cp ../*_script.sh .;`;

  return executeCommandInShell(socketId, bashCommand);
}

async function getResultFromGradingScript(repoPath, bonusDate, socketId) {
  const bashCommand = `cd ${repoPath};ls;
                   chmod 777 *.sh;
                   ./*.sh ${bonusDate}`;

  const res = await executeCommandInShell(socketId, bashCommand);

  if (res.indexOf('Error') >= 0) return Promise.reject({ message: res });

  return { graders: res ? res.split('\n') : null };
}

async function getHTMLOutPutFileList(name, socketId) {
  const bashCommand = `cd .private_repo/${name};
                    shopt -s nullglob;
                    files=(*/*.out.html);
                    printf "%s\\n" "$\{files[@]}";`;

  return executeCommandInShell(socketId, bashCommand);
}

async function getBonusList(name, socketId) {
  const bashCommand = `cd .private_repo/${name};
                         cat bonusList;`;
  return executeCommandInShell(socketId, bashCommand);
}

async function saveStudentResults(data, previewList, repo, name, bonusList) {
  data.previewList = previewList.split('\n');

  return saveStudents({
    body: {
      repoId: repo,
      assignmentId: name,
      students: data.previewList.map(fileName => {
        return {
          graderId: fileName.split('/')[0],
          studentId: fileName.split('/')[1].replace(/\..*/, '')
        };
      }),
      bonusList: bonusList.split('\n')
    }
  });
}

async function executeCommandInShell(socketId, bashCommand) {
  return command({
    body: {
      socketId,
      command: bashCommand
    }
  });
}

async function transferFileContentToServer(socketId, content, filePath) {
  return transfer({
    body: {
      socketId,
      content,
      filePath
    }
  });
}
