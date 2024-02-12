# Add these lines to your `~/.zshrc` file
#   (or `~/.bashrc` for Bash)!

# unstage local `git commit` made by accident
alias unstage='git reset --soft HEAD~1'

# gpg - list secret keys
alias gpgl='gpg --list-secret-keys'

# git - commit all!
#
# saves you time from having to do:
#   $ git add .
#   $ git commit -m "<msg>"
alias gca='git commit -am $@'

# delete GPG key
gpgd () {
    gpg --batch --yes --delete-secret-key $1
    gpg --batch --yes --delete-key $1
}

# delete and re-create the latest tag on remote
rmtag () {
    TAG=$(git describe --tags --abbrev=0)
    export TAG
    git tag -d "$TAG"
    git tag "$TAG"
    git push origin :"$TAG"
    git push origin "$TAG"
}
