#!/bin/bash
# Install git
if [ $(dpkg-query -W -f='${Status}' git 2>/dev/null | grep -c "ok installed") -eq 0 ];
then
    apt-get --assume-yes install git;
fi

# Install xprintidle
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
        os_version=`lsb_release -d | cut -d " " -f 2`
        arch=`uname -m`
        os_version="14.04"
        arch="i686"

        case "$os_version $arch" in
            "14.04 i686")    url="http://archive.ubuntu.com/ubuntu/pool/universe/x/xprintidle/xprintidle_0.2-9_i386.deb" ;;
            "16.04 amd_x64") url="http://archive.ubuntu.com/ubuntu/pool/universe/x/xprintidle/xprintidle_0.2-10_amd64.deb" ;;
            # TODO: añadir más versiones y arquitecturas cuando sea necesario
        *)
            echo "No se ha podido instalar $package. No puedo continuar..."
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
echo "$package ya está instalado."

# Instalación de checker
TEMP_DIR="git-checker"
cd /tmp
if [ -d "$TEMP_DIR" ]; then rm -Rf $TEMP_DIR; fi
mkdir git-checker
cd git-checker
git clone https://github.com/Canx/checker
cd checker

# TODO: mover parte de instalación aquí
echo "Instalando checker..."
sudo ./checker.sh
