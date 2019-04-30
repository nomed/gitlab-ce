# Git tricks

Here are some commands that you may not need to use every day, but which can come in
handy when needed.

## bash

### Add another url to a remote, so both urls get updated on every push
git remote set-url --add <remote_name> <remote_url>

### removes last commit and leaves the changes made in 'unstaged'
git reset --soft HEAD^

### unstages a certain number of commits (3 here) from HEAD
git reset HEAD^3

### unstages changes to a certain file to HEAD
git reset <filename>

### reverts a file to what's in HEAD.  REMOVES changes made.
git checkout <filename>
git reset --hard <filename>

### undo a previous commit.  this does the opposite by creating a new commit
git revert <commit-sha>

### create a new message for last commit
git commit --amend

### add a file to the last commit
git add <filename>
git commit --amend
# add --no-edit to NOT edit the commit message

### stash changes - both below are equivalent
git stash save
git stash

### unstash your changes
git stash apply

### discard your stashed changes
git stash drop

### apply and drop your stashed changes
git stash pop

### check the git history of a file
git log -- <file>
git log <file>

### find the tags that contain a particular SHA
git tag --contains <sha>

### check the content of each change to a file
gitk <file>

### check the content of each change to a file, follows it past file renames
gitk --follow <file>

## Debugging

### Use a custom SSH key for a git command

GIT_SSH_COMMAND="ssh -i ~/.ssh/gitlabadmin" git <command>

### Debug cloning

GIT_SSH_COMMAND="ssh -vvv" git clone <git@url>     # with SSH
GIT_TRACE_PACKET=1 GIT_TRACE=2 GIT_CURL_VERBOSE=1 git clone <url>     # with HTTPS

## Rebasing

### Rebase your branch onto master.
# the -i flag stands for 'interactive'
git rebase -i master

### Continue the rebase if paused
git rebase --continue

### Additional rebasing tips

Rerere _reuses_ recorded solutions to the same problems when repeated
`git config --global rerere.enabled true`

Use the reference log (reflog) to show the log of reference changes to HEAD
`git reflog`