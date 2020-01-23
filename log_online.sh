#!/bin/bash
# Registramos cuando se apaga y enciende el ordenador
pc=`hostname`
mac=`LANG=C ip link show | awk '/link\/ether/ {print $2}' | head -1`
if [ -z $1 ]; then estado="FALSE"; else estado="TRUE"; fi
echo $pc
echo $mac
echo $estado
curl -L https://script.google.com/macros/s/AKfycbzp46iNNXaMBaBPn8q8zTZF0jr2_Vf7ni6L18iGkAtXpb3-js4/exec?q=registrar/$pc/$mac/$estado
