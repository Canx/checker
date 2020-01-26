#!/bin/bash
# Registramos cuando se apaga y enciende el ordenador
# El parámetro $1 nos da información adicional del apagado
pc=`hostname`
device=`LANG=C ip route | grep "default" | cut -d" " -f5`
mac=`LANG=C ip link show $device | awk '/link\/ether/ {print $2}' | head -1`
ip=`LANG=C ip address show $device | awk '/[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*/ {print$2}'`
logger "Registrando apagado $1..."
curl -L https://script.google.com/macros/s/AKfycbzp46iNNXaMBaBPn8q8zTZF0jr2_Vf7ni6L18iGkAtXpb3-js4/exec?q=registrar/$pc/$mac/$ip/$1
