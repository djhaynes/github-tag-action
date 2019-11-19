#!/bin/bash

# config
default_semvar_bump=${DEFAULT_BUMP:-minor}
with_v=${WITH_V:-false}
release_branches=${RELEASE_BRANCHES:-master}

pre_release="true"
IFS=',' read -ra branch <<< "$release_branches"
for b in "${branch[@]}"; do
    echo "Is $b a match for ${GITHUB_REF#'refs/heads/'}"
    if [[ "${GITHUB_REF#'refs/heads/'}" =~ $b ]]
    then
        pre_release="false"
    fi
done
echo "pre_release = $pre_release"

# get latest tag
tag=$(git describe --tags `git rev-list --tags --max-count=1`)
tag_commit=$(git rev-list -n 1 $tag)

# get current commit hash for tag
commit=$(git rev-parse HEAD)

if [ "$tag_commit" == "$commit" ]; then
    echo "No new commits since previous tag. Skipping..."
    exit 0
fi

# if there are none, start tags at 0.0.0
if [ -z "$tag" ]
then
    log=$(git log --pretty=oneline)
    tag=0.0.0
else
    log=$(git log $tag..HEAD --pretty=oneline)
fi

# get commit logs and determine home to bump the version
# supports #major, #minor, #patch (anything else will be 'minor')
case "$log" in
    *#major* ) new=$(semver bump major $tag);;
    *#minor* ) new=$(semver bump minor $tag);;
    *#patch* ) new=$(semver bump patch $tag);;
    * ) new=$(semver bump `echo $default_semvar_bump` $tag);;
esac

# prefix with 'v'
if $with_v
then
    new="v$new"
fi

if $pre_release
then
    new="$new-${commit:0:7}"
fi

echo "NEW: $new"

git pull origin master
git config --global user.email "you@example.com"
git config --global user.name "Your Name"
echo "$new" > VERSION.md
git commit -m "incrementing VERSION.md" VERSION.md
git push origin master
git tag $new
