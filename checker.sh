#!/bin/bash
                                               # Here I remark changes

SCRIPT="$(readlink -f "$0")"
SCRIPTFILE="$(basename "$SCRIPT")"             # get name of the file (not full path)
SCRIPTPATH="$(dirname "$SCRIPT")"
SCRIPTNAME="$0"
ARGS=( "$@" )                                  # fixed to make array of args (see below)
BRANCH="master"

self_update() {
    cd "$SCRIPTPATH"
    git fetch

                                               # in the next line
                                               # 1. added double-quotes (see below)
                                               # 2. removed grep expression so
                                               # git-diff will check only script
                                               # file
    [ -n "$(git diff --name-only "origin/$BRANCH" "$SCRIPTFILE")" ] && {
        echo "Found a new version of me, updating myself..."
        git pull --force
        git checkout "$BRANCH"
        git pull --force
        echo "Running the new version..."
        cd -                                   # return to original working dir
        exec "$SCRIPTNAME" "${ARGS[@]}"

        # Now exit this old instance
        exit 1
    }
    echo "Already the latest version."
}
self_update
echo “some code”
