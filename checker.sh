#!/bin/bash
# Version: 0.3

minutos=${1:-30}

USER=""
DISPLAY=""

# For updating script
SCRIPT="$(readlink -f "$0")"
SCRIPTFILE="$(basename "$SCRIPT")"             # get name of the file (not full path)
CRONFILE="${SCRIPTFILE%.*}"
SCRIPTPATH="$(dirname "$SCRIPT")"
SCRIPTNAME="$0"
ARGS=( "$@" )                                  # fixed to make array of args (see below)
BRANCH="master"


get_displays() {
    declare -A disps usrs
    usrs=()
    disps=()

    for i in $(users);do
        [[ $i = root ]] && continue # skip root
        usrs[$i]=1
    done # unique names

    for u in "${!usrs[@]}"; do
        for i in $(sudo ps e -u "$u" | sed -rn 's/.* DISPLAY=(:[0-9]*).*/\1/p');do
            disps[$i]=$u
        done
    done

    for d in "${!disps[@]}";do
        USER=${disps[$d]}
        DISPLAY=$d
        logger "$SCRIPTFILE User: $USER, Display: $DISPLAY"
        export DISPLAY=$DISPLAY
    done
}


# Check update script
if [ ! -f "/tmp/checker.log" ]; then
   . $SCRIPTPATH/install.sh
   . $SCRIPTPATH/log.sh "encendido"
   touch /tmp/checker.log
   exit 1
fi


# Empezamos el script
get_displays

idletime=$((60*1000*$minutos))

idle=`sudo -u $USER env DISPLAY=$DISPLAY /usr/bin/xprintidle`

# This creates a date file used when no user is logged in
if [ -z $idle ]; then
    if [ -f /tmp/idle ]; then
        idle=`cat /tmp/idle`
    else
        idle=0
    fi
    idle=$((idle+60000))
    echo $idle > /tmp/idle
else
    rm -rf /tmp/idle
fi

logger "$SCRIPTFILE Comprobando si han pasado $minutos minutos de inactividad."
if [[ $idletime -lt $idle ]]; then
   logger "$SCRIPTFILE apagamos el ordenador"
   . $SCRIPTPATH/log.sh "automatico_checker"
   echo "shutdown" >> /tmp/checker.log
   /sbin/shutdown -P now
else
   logger "$SCRIPTFILE no apagamos aun. Faltan $((($idletime-$idle)/60000)) minutos."
fi
