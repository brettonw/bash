#! /usr/bin/env bash

# git functions used frequently
function gitgo {
    #git add --all . && git commit && git push origin HEAD;
    gitgo.sh;
}

function gitrevert {
    git reset --hard HEAD && git clean -f;
}

function gitb {
	DEFAULT_GIT_BRANCH=$(git remote show origin | grep "HEAD branch" | cut -d ":" -f 2 | xargs);
    local branchname="${1,,}";
    local srcbranchname="${2,,}";
    if [ -z $srcbranchname ]; then
        read -p "What is the source branch? [$DEFAULT_GIT_BRANCH]" srcbranchname;
        if [ -z $srcbranchname ]; then
            srcbranchname=$DEFAULT_GIT_BRANCH;
        fi
    fi
    git checkout $srcbranchname &&
    git pull &&
    git checkout -b $branchname &&
    git push -u origin $branchname;
    #git branch --set-upstream-to=origin/$1 $1;
}

function gitpul {
	DEFAULT_GIT_BRANCH=$(git remote show origin | grep "HEAD branch" | cut -d ":" -f 2 | xargs);
    git pull origin $DEFAULT_GIT_BRANCH;
}

function gitchk {
	DEFAULT_GIT_BRANCH=$(git remote show origin | grep "HEAD branch" | cut -d ":" -f 2 | xargs);
    git checkout $DEFAULT_GIT_BRANCH && git pull;
}

function gitreset {
    git reset --hard HEAD && git clean -fd;
}

