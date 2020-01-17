#!/bin/bash

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

self_update() {
    cd "$SCRIPTPATH"
    git fetch
    [ -n "$(git diff --name-only "origin/$BRANCH" "$SCRIPTFILE")" ] && {
        logger "$SCRIPTFILE Se ha encontrado una actualización, actualizando..."
        git pull --force
        git checkout "$BRANCH"
        git pull --force
        cd -                                   # return to original working dir
    }
    logger "Ya es la última versión."
}

check_xprintidle() {
   if [ $(dpkg-query -W -f='${Status}' xprintidle 2>/dev/null | grep -c "ok installed") -eq 0 ];
   then
      apt-get install xprintidle;
   fi
}

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


check_xprintidle

# TODO: check_git

# Install script and cron if we are not in installation path
if [ $SCRIPTPATH != "/usr/local/bin/checker" ]; then 
   logger "$SCRIPTFILE Instalando script..."
   cp -r $SCRIPTPATH /usr/local/bin/
   chown root:root -R /usr/local/bin/checker
   logger "$SCRIPTFILE Instalando cron..."
   echo "*/1 * * * *    root    /usr/local/bin/checker/$SCRIPTFILE" >> /tmp/$CRONFILE
   mv /tmp/$CRONFILE /etc/cron.d/
   chown root:root /etc/cron.d/$CRONFILE
else
   # Check update script
   if [ ! -f "/tmp/checker.log" ]; then
       self_update
       touch /tmp/checker.log
       exit 1
   fi
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
   /sbin/shutdown -P now
else
   logger "$SCRIPTFILE no apagamos aun. Faltan $((($idletime-$idle)/60000)) minutos."
fi
