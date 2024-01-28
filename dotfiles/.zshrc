# delete GPG key

alias gpgl='gpg --list-secret-keys'

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
