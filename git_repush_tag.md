1. While still on any branch

# TAG=v1.1
export TAG=$(git describe --tags --abbrev=0)

git tag -d $TAG

> Source: https://gist.github.com/rnag/1e2221a5df962fb997083e83ca034762

2. Create the tag again: This will "move" the tag to point to your latest commit on that branch

git tag $TAG

3. Delete the tag on remote

git push origin :$TAG

4. Create the tag on remote

git push origin $TAG
