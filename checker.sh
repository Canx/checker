#!/bin/bash

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")
SCRIPTNAME="$0"
ARGS="$@"
BRANCH="master"

self_update() {
    cd $SCRIPTPATH
    git fetch

    [ -n $(git diff --name-only origin/$BRANCH | grep $SCRIPTNAME) ] && {
        echo "Found a new version of me, updating myself..."
        git pull --force
        git checkout $BRANCH
        git pull --force
        echo "Running the new version..."
        exec "$SCRIPTNAME" "$@"

        # Now exit this old instance
        exit 1
    }
    echo "Already the latest version."
}

main() {
   # 1.- check that script is installed in crontab as desired
   #     we have to diff crontab lines.
   # 2.- run the commands
   echo "Running"
}

self_update
main
