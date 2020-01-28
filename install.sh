#!/bin/bash

SCRIPT="$(readlink -f "$0")"
SCRIPTFILE="$(basename "$SCRIPT")"
SCRIPTPATH="$(dirname "$SCRIPT")"
SCRIPTNAME="$0"
ARGS=( "$@" ) 
BRANCH="master"
INSTALLPATH="/usr/local/bin/checker"

# Install git
install_git() {
    echo "Comprobando si git está instalado..."
    if [ $(dpkg-query -W -f='${Status}' git 2>/dev/null | grep -c "ok installed") -eq 0 ];
    then
        echo "Instalando git.."
        apt-get --assume-yes install git;
    else
        echo "OK!"
    fi
}

install_curl() {
    echo "Comprobando si curl está instalado..."
    if [ $(dpkg-query -W -f='${Status}' curl 2>/dev/null | grep -c "ok installed") -eq 0 ];
    then
        echo "Instalando curl.."
        apt-get --assume-yes install curl;
    else
        echo "OK!"
    fi
}

# Install xprintidle
install_xprintidle() {
    package="xprintidle"
    echo "Comprobando si $package está instalado..."
    if [ $(dpkg-query -W -f='${Status}' $package 2>/dev/null | grep -c "ok installed") -eq 0 ];
    then
        echo "No está instalado."
        # check if we can install package
        if [ -z $(apt-cache show $package) ];
        then
            echo "El paquete $package no está en el repositorio. Instalando manualmente..."
            # install package manually
            os_version=`lsb_release -d | cut -d " " -f 2 | cut -d. -f1-2`
            arch=`uname -m`
    
            case "$os_version $arch" in
                "14.04 i686")    url="http://archive.ubuntu.com/ubuntu/pool/universe/x/xprintidle/xprintidle_0.2-9_i386.deb" ;;
                "16.04 amd_x64") url="http://archive.ubuntu.com/ubuntu/pool/universe/x/xprintidle/xprintidle_0.2-10_amd64.deb" ;;
                # TODO: añadir más versiones y arquitecturas cuando sea necesario
            *)
                echo "No se ha podido instalar $package en $os_version $arch. No puedo continuar..."
                exit 1
                ;;
            esac
            echo "Descargando $package manualmente para $os_version y $arch."
            curl $url -o /tmp/$package.deb
            sudo dpkg -i /tmp/$package.deb
        else
            echo "Instalando $package desde el repositorio."
            sudo apt-get --assume-yes install $package;
        fi
    fi
    echo "OK!"
}

install_checker() {
       echo "Instalando checker..."
       TEMP_DIR="git-checker"
       cd /tmp
       if [ -d "$TEMP_DIR" ]; then rm -Rf $TEMP_DIR; fi
       mkdir git-checker
       cd git-checker
       git clone https://github.com/Canx/checker
  
       # EN PRODUCCION 
       cp -r checker /usr/local/bin/ 
       # PARA PROBAR
       #cp -r $SCRIPTPATH /usr/local/bin/
       chown root:root -R /usr/local/bin/checker
 
}

update_checker() {
    cd $SCRIPTPATH
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

install_or_update_cron() {
    # TODO: Comprobar si existe ya el fichero
    # TODO: Si no existe comprobar si hay que actualizarlo
    cp $INSTALLPATH/cron.d/checker /etc/cron.d/
}

install_or_update_service() {
    cp $INSTALLPATH/init.d/checker /etc/init.d/
    chmod 755 /etc/init.d/checker

    if hash systemctl 2>/dev/null; then
        systemctl daemon-reload
        systemctl start checker
    else
        update-rc.d checker defaults 99 1
        update-rc.d checker enable
    fi
}

install_or_update_checker() {
    # 1. checker
    if [ $SCRIPTPATH != $INSTALLPATH ]; then
       install_checker
   else
       update_checker
    fi
    
    # 2.- cron
    install_or_update_cron
    
    # 3.- servicio para registrar encendidos y apagados
    install_or_update_service
}

## MAIN ## 
install_git
install_xprintidle
install_curl
install_or_update_checker
