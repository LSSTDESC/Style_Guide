#!/bin/bash

# q/d way of getting compiled products onto GitHub without saving their histories.

function parse_git_branch {
    s=`git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ \1/' | tr -d ' '`
    echo "$s"
}

current=$(parse_git_branch)
orphan=compiled
files=main.pdf
message=upload
safe=safety

[ ${#files[@]} -ge 1 ] || {
    echo "No files to upload."
    exit
}

# because this process is destructive, make a copy of everything
mkdir $safe || exit $?
rm -f $safe/* # oh, the irony
cp -v $files $safe/

git checkout --orphan $orphan && \
    git rm -rf . && \
    git add $files && \
    git commit -m "$message" && \
    git push -f origin $orphan

git checkout $current
git branch -D $orphan

mv -v $safe/* .
rmdir $safe
