#! /usr/bin/env bash

# back up to the root of the git repository and merge in the default branch (usually development)
cd $(git rev-parse --show-toplevel);
DEFAULT_GIT_BRANCH=$(git remote show origin | grep "HEAD branch" | cut -d ":" -f 2 | xargs);
pwd
echo "merging '$DEFAULT_GIT_BRANCH'...";
git pull origin $DEFAULT_GIT_BRANCH;
echo "done merging '$DEFAULT_GIT_BRANCH'";

# check to see if there is anything to do
nothingToCommit=$(git status | grep "nothing to commit");
if [ -z "$nothingToCommit" ]; then
    # set up the temp file
    commitMessageFile=$(mktemp /tmp/commit.XXXXXXXXX);
    echo "Commit staged in: $commitMessageFile";

    # use the temp file to get a list of files to check in
    echo "FILES FOR CHECKIN (remove lines for files you do not want to check in)" > $commitMessageFile;
    echo >> $commitMessageFile;

    # get the tracked files that are changed
    IFS=$'\n';
    filesToCommit=($(git status | grep -E 'modified: |new file: |deleted: '));
    for file in "${filesToCommit[@]}"; do
        action=${file%%:*}; action="${action//[[:space:]]/}";
        file=${file#*:}; file="${file//[[:space:]]/}";
        echo "$action: $file";
        echo "$action: $file" >> $commitMessageFile;
    done

    # get the untracked files
    untrackedFiles=($(git ls-files --others --exclude-standard));
    for file in "${untrackedFiles[@]}"; do
        file="${file//[[:space:]]/}";
        echo "untracked: $file" >> $commitMessageFile;
    done

    # let the user see the list of files, edit, and then grab the resulting list
    eval "$EDITOR $commitMessageFile";
    filesToCommit=($(cat $commitMessageFile | grep -E 'modified: |new file: |deleted: |untracked: '));

    # add the files to the change list
    counter="";
    for file in "${filesToCommit[@]}"; do
        action=${file%%:*}; action="${action//[[:space:]]/}";
        file=${file#*:}; file="${file//[[:space:]]/}";
        #echo "git add $file";
        git add $file;
        counter="$counter.";
    done

    # if there are files
    if [ -z "$counter" ]; then
        echo "Nothing to check-in."
    else
        # get the branch name and construct the commit message file
        branchName=$(git branch | grep \* | cut -d ' ' -f2);
        read -p "Subject Line: ($branchName) " subjectLine;
        commitMessageFile=$(mktemp /tmp/commit.XXXXXXXXX);
        echo "$branchName $subjectLine" > $commitMessageFile;
        echo >> $commitMessageFile; echo "Change Description: " >> $commitMessageFile;
        eval "$EDITOR $commitMessageFile";

        # checkin the changes
        git commit --file $commitMessageFile && git push origin HEAD;
    fi

    # clean up
    rm -f $commitMessageFile;
else
    echo "Nothing to check-in."
fi
