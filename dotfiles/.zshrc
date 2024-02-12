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

# don't remember, think it helps you run interactive shell in Docker container?
cdi () {
    docker run --rm -it --platform linux/amd64 --entrypoint /bin/bash $1
}

# automatically activate Python virtual environment
# (usually a `venv` or `.venv` folder) when
# one `cd`s into a directory.
cd () {
    builtin cd "$@"
    if [[ -z "$VIRTUAL_ENV" ]] ; then
        ## If env folder is found then activate the vitualenv
        if [[ -d ./venv ]] ; then
            source ./venv/bin/activate
            elif [[ -d ./.venv ]] ; then
            source ./.venv/bin/activate
        fi
    else
        ## check the current folder belong to earlier VIRTUAL_ENV folder
        # if yes then do nothing
        # else deactivate
        parentdir="$(dirname "$VIRTUAL_ENV")"
        if [[ "$PWD"/ != "$parentdir"/* ]] ; then
            deactivate
        fi
    fi
}
