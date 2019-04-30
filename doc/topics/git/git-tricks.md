# Git tricks

Here are some commands that you may not need to use every day, but which can come in
handy when needed.

## bash

### Add another URL to a remote, so both URLs get updated on each push

`git remote set-url --add <remote_name> <remote_url>`

### Remove last commit and leave the changes in unstaged

`git reset --soft HEAD^`

### Unstage a certain number of commits from HEAD

For example, to unstage 3 commits

`git reset HEAD^3`

### Unstage changes to a certain file from HEAD

`git reset <filename>`

### Revert a file to HEAD state and remove changes

```
git checkout <filename>
git reset --hard <filename>
```

### Undo a previous commit by creating a new replacement commit

`git revert <commit-sha>`

### Create a new message for last commit

`git commit --amend`

### Add a file to the last commit

```
git add <filename>
git commit --amend
```

add `--no-edit` to NOT edit the commit message

### Stash changes

`git stash save`
or
`git stash`

### unstash your changes

`git stash apply`

### discard your stashed changes

`git stash drop`

### apply and drop your stashed changes

`git stash pop`

### check the git history of a file

```git log -- <file>
git log <file>```

### find the tags that contain a particular SHA

`git tag --contains <sha>`

### check the content of each change to a file

`gitk <file>`

### check the content of each change to a file, follows it past file renames

`gitk --follow <file>`

## Debugging

### Use a custom SSH key for a git command

`GIT_SSH_COMMAND="ssh -i ~/.ssh/gitlabadmin" git <command>`

### Debug cloning

`GIT_SSH_COMMAND="ssh -vvv" git clone <git@url>` with SSH
`GIT_TRACE_PACKET=1 GIT_TRACE=2 GIT_CURL_VERBOSE=1 git clone <url>` with HTTPS

## Rebasing

### Rebase your branch onto master

The -i flag stands for 'interactive'

`git rebase -i master`

### Continue the rebase if paused

`git rebase --continue`

### Additional rebasing tips

Rerere _reuses_ recorded solutions to the same problems when repeated

`git config --global rerere.enabled true`

Use the reference log (reflog) to show the log of reference changes to HEAD

`git reflog`