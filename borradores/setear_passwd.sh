#!/bin/bash
#archivo de usuario creados con exito
usuarios_creados="./logs/usuarios_creados.txt"

if [ -z $password ]; then
    echo "No se puede colocar password a los usuarios"
else
    for i in $(cat $usuarios_creados); do
        echo $i:$password | sudo chpasswd
    done
fi

