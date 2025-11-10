#!/bin/bash


##Definimos variables globales
contendio_arch=""
mostrar_info=0
poner_contraseña=0
password=""

##Validar que al menos recibe un parametro
if [ -z "$#" ]; then
    exit 2
fi


##Validacion de parametros pasados al script.
while getopts "ic:" opt; do
    case "$opt" in
        i)
            ##Verificar que se haya pasado el -i como paramentro
            ##Asignar un valor que diga que hay que mostrar la informacion de cada usuario creado
            ## y tambien cuando no pueda crear un usuario
            ##ejemplo: mostrar_info=1
        ;;
        c)
            ##Verificar que se haya pasado el -c como parametro
            ##Asignar un valor que diga que hay que establecer una contraseña para todos los usuarios a crear
            ##Ejemplo, poner_contraseña=1, guardar argumento de la contraseña "password=-p $OPTARG"
        ;;
        *)
            ##Verificar que no haya ningun comando incorrecto, si lo hay se debe mostrar un mensaje con el error
            ##Asignar un codigo de salida "exit 1"
        ;;
    esac 
done

##Al ejecutar getops, nos quedamos con el archivo pasado como parametro en $1
shift $((OPTIND-1))
##Definimos variable arch=$1

##Se supone que $1 ahora sera el archivo pasado como parametro

##Verificacion del tipo de archivo
if ! [ -f "$arch" ]; then
    echo "Solo se permiten archivos de tipo file"  >&2
    exit 2
##Verficacion de permiso lectura del archivo
elif ! [ -r $arch ]; then
    echo "el archivo no tiene permisos de lectura" >&2
    exit 3
##Verificacion de archivo no vacio    
elif [ -z $(cat "$arch") ]; then
    echo "El archivo esta vacio" >&2
    exit 4
fi


##Crear usuarios pasados por el archivo
##Cantidad de usuarios a crear, determinado por la cantidad de lineas del archivo
usuarios_a_crear=$(cat $arch | wc -l)

##
if [ $mostrar_info=1 ]; then
    ##Recorremos linea a linea del archivo con un for, para ir creandolos
    for i=1 in $usuarios_a_crear; do
        nombre_usuario=$(echo $arch | cut -d: -f1)
        descripcion=$(echo $arch | cut -d: -f2)
        directorio_home=$(echo $arch | cut -d: -f3)
        crear_directorio=$(echo $arch | cut -d: -f4)
        shell=$(echo $arch | cut -d: -f5)
        ##verificar si agreagar descripcion o dejarla por defecto
        if ! [ -z $descripcion ]; then
            agregar_descripcion="-c $descripcion"
        fi
        ##verificar si agregar shell, o dejarla por defecto
        if ! [ -z $shell ]; then
            agregar_shell="-s $shell"
        fi

        if [ $crear_directorio="SI" ]; then
            agregar_directorio="-m $directorio_home"
        elif [ $crear_directorio="NO" ]; then
            agregar_directorio="-d $directorio_home"                  
        fi
        ##comando para agregar usuario
        useradd $nombre_usuario $agregar_descripcion $agregar_directorio $agregar_shell
    done
fi
    












