# PAGrader

This is a web application to help save time grading introductory programming assignments.

<b>Brief description of the problem</b>

1. Students submitted assignments that are stored on a server
2. Tutors SSH into server, compiles and runs each program manually
3. Grades are then individually sent through email to the students and professor

This application helps solve this problem by allowing the professor to log into the application which will then internally SSH into the school's server and run my grading script on the server. The grading script will compile each of the student's program and merge the output/input into a file on the school's server. (We keep these files on the school's server because we are only using heroku's and mlab's free tier so we want to preserve as much space as possible.) Graders are then able to log into the web application and view these files while adding grades/comments that they can submit.


#Development
## Installation
    yarn

## Setup
1. Create a file at server/config/localSecrets.js
2. Add the following code replacing the values
```
module.exports = {
  db: <You can either point to a local MongoDB or use a free dev tier from https://mlab.com/>,

  sshServerInfo: (This is the SSH Server that the SSH Accounts are used on. Ask me for info or you can use your tutor account. For development I use shell.xshellz.com),

  sshTestUser: (This is the SSH Login to run SSH tests)
  sshTestPassword: (This is the SSH Password to run SSH tests)
};
```

## Local Development

    yarn start

## Building and Running Production Server

    yarn build
    yarn start

## Testing Server Code

    yarn test
    
To run files individually

    jest <path to test file>

When you run all the tests notice that in your server account there will be a directory called GRADERS
The test scripts create a database for your repo, and upload 2 sample .c files into that folder
You can then use the UI to run the grading script and see the output

**If you run the grading scripts and want to then test with CSE11 refer to ieng6/xshells accounts section on this doc**

    
## GIT
Creating your own local branch
    
    git checkout -b <your branch name>
to push your local branch to remote
    
    git push -u origin <your branch name>
    
Lets say you are going through the UI and you want to find a file that is controlling that component
You can inspect the page on Chrome and find a uniqe set of character then use
    
    git grep "<text to search for>"
    
If you want to record the current state of the working directory and the index, but want to go back to a clean working directory use
    
    git stash
    
When you are done and want your files back
    
    git stash pop

[Info on git stash](https://git-scm.com/docs/git-stash)
    
If you want to go to a previous commit use interactive rebase
    
    git rebase -i HEAD~4

The above command will output the previous 4 commits

    [interactive rebase](https://robots.thoughtbot.com/git-interactive-rebase-squash-amend-rewriting-history)
    
    Example:
    ```
    pick 07c5abd Introduce OpenPGP and teach basic usage
    pick de9b1eb Fix PostChecker::Post#urls
    pick 3e7ee36 Hey kids, stop all the highlighting
    pick fa20af3 git interactive rebase, squash, amend

    # Rebase 8db7e8b..fa20af3 onto 8db7e8b
    #
    # Commands:
    #  p, pick = use commit
    #  r, reword = use commit, but edit the commit message
    #  e, edit = use commit, but stop for amending
    #  s, squash = use commit, but meld into previous commit
    #  f, fixup = like "squash", but discard this commit's log message
    #  x, exec = run command (the rest of the line) using shell
    #
    # These lines can be re-ordered; they are executed from top to bottom.
    #
    # If you remove a line here THAT COMMIT WILL BE LOST.
    #
    # However, if you remove everything, the rebase will be aborted.
    #
    # Note that empty commits are commented out
    ```
    
    you can reorder the commits to move a previous commit to the top
    when you are done you can reorder them again
    
If you want to get rid of what you have and work on a clean directory based on master
    
    git fetch master
    git reset --hard origin/master

A log of where your HEAD and branch references have been for the last few months
    
[Info on reflog](https://git-scm.com/book/en/v1/Git-Tools-Revision-Selection#RefLog-Shortnames)
    
    git reflog

To reset your current state into a previous one

    git reset --hard HEAD@{<number shown in reflog>}
    
Undo the most recent commit but keep your changes
    
    git reset HEAD~1
    
## ieng6/xshells accounts
    
**You can ONLY use one account for either CSE5a or CSE11
If you attempt to create a repo for each class the script will FAIL**
    
**When you create a repo for your ieng6 account using either CSE5a or CSE11**
    
    1. a .private_repo directory will be created in ~
    2. Either the java or C grading script will be uploaded to that directory
    
**When you grade assignments**
   
    1. The folder that contains the assignments on your ieng6 account will be coppied to .private_repo
    2. The grading script will be moved copied from ~/.private_repo to ~/.private_repo/<assignments to grade dir>
    
**If you create a repo for one class you must do the following to use another class**
    
    1. If you are using mlab or using mongo on your local machine
        1. delete the collections on your database
    2. ssh into your ieng6 account that you are using to test
    3. rm -r ~/.private_repo
        

## Debugging the grading script (Java / C Script)
When trying to debug infinite loop programs please verify that you don't leave any processes running

Check for the processes running by using this command

    ps aux | grep <ACCOUNT>

Kill any processes that should not be running

    kill -15 <PID>

## Contributing
If you are working on a bug/feature **create your own branch** refer to GIT section on this doc
**NEVER push to master** always create your own branch and push to that, then create a pull request for code review

#### Plugins to install with Sublime IDE (Development)

1. Package Control
2. Babel
3. Git
4. SublimeLinter
5. SublimeLinter-contrib-eslint
