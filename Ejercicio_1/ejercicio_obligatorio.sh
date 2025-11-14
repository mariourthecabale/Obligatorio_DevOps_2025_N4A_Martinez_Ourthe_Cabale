#!/bin/bash

##Definimos variables globales
mostrar_info=false
password=""
existe_directorio=""
set_passwd=false
IFS="
"
mostrar_info=True
function crear_usuarios {
    usuarios_a_crear=$(cat $arch| wc -l)
    cant_usuarios_creados=$(cat $arch| wc -l)
    for i in $(cat $arch); do
        nombre_usuario=$(echo $i | cut -d: -f1)
        descripcion=$(echo $i | cut -d: -f2)
        directorio_home=$(echo $i | cut -d: -f3)
        crear_directorio=$(echo $i| cut -d: -f4)
        shell=$(echo $i | cut -d: -f5)
        ##Definimos la info por defecto a mostrar, en caso de que sea necesaria cambiarla por error al crear el usuario se cambiara su valor
        info=$(echo "Usuario $nombre_usuario creado con exito con datos indicados:\n\tComentario: $descripcion\n\tDir home: $directorio_home\n\tAsegurado existencia de directorio home: $crear_directorio\n\tShell por defecto: $shell") 
       
        ##verificar si agregar shell, o dejarla por defecto
        if [ -z "$shell" ]; then
            shell="/bin/bash"            
        fi
 
        if [ -z "$descripcion" ]; then
            descripcion=""
        fi
 

        ##Evakuamos si el directorio existe
        if [ -d "$directorio_home" ]; then
            existe_directorio=$(echo $?)
        else
            existe_directorio=$(echo $?)
        fi

        ##Evaluamos si descripcion esta vacia o no
        if ! [ -z $descripcion ]; then
            ##Crear directorio si no existe y colocar el usuario dentro del mismo
            if [[ ("$crear_directorio" == "SI" && $existe_directorio -eq 1) ]]; then
                #useradd -c "$descripcion" -m -d "$directorio_home" -s "$shell" "$nombre_usuario"
                echo $nombre_usuario >> "logs/usuarios_creados.txt"
            ##Agregar usuario a directorio existente
            elif [[ ("$crear_directorio" == "NO" && $existe_directorio -eq 0) || ("$crear_directorio" == "SI" &&  $existe_directorio -eq 0) || (-z "$crear_directorio" && $existe_directorio -eq 0) ]]; then
                #useradd -c "$descripcion" -d "$directorio_home" -s "$shell" "$nombre_usuario"
                echo $nombre_usuario >> "logs/usuarios_creados.txt"
            ##Crear directorio home por defecto, si campo "crear_directorio" está vacio.
            elif [[ (-z "$crear_directorio" && $existe_directorio -eq 1) ]]; then
                #useradd -c "$descripcion" -s "$shell" "$nombre_usuario"
                echo $nombre_usuario >> "logs/usuarios_creados.txt"
            ##No se puede crear usuario
            ######## PENDIENTE VALIDAR QUE HACER CUANDO CAMPO "CREAR DIRECTORIO" CONTIENE CUALQUIER VERDURA
            elif [ "$crear_directorio" == "NO" ] && [ $existe_directorio -eq 1 ]; then
                info=$(echo "ATENCION: el usuario $nombre_usuario no pudo ser creado $nombre_usuario")
                cant_usuarios_creados=$((cant_usuarios_creados - 1)) 
            fi
        else
            #Crear directorio si no existe y colocar el usuario dentro del mismo
            if [[ ("$crear_directorio" == "SI" && $existe_directorio -eq 1) ]]; then
                #useradd -m -d "$directorio_home" -s "$shell" "$nombre_usuario"
                 echo $nombre_usuario >> "logs/usuarios_creados.txt"
            ##Agregar usuario a directorio existente
            elif [[ ("$crear_directorio" == "NO" && $existe_directorio -eq 0) || ("$crear_directorio" == "SI" &&  $existe_directorio -eq 0) || (-z "$crear_directorio" && $existe_directorio -eq 0) ]]; then
                #useradd -d "$directorio_home" -s "$shell" "$nombre_usuario"
                 echo $nombre_usuario >> "logs/usuarios_creados.txt"
            ##Crear directorio home por defecto, si campo "crear_directorio" está vacio.
            elif [[ (-z "$crear_directorio" && $existe_directorio -eq 1) ]]; then
                 #useradd -s "$shell" "$nombre_usuario"
                 echo $nombre_usuario >> "logs/usuarios_creados.txt"
            ##No se puede crear usuario
            ######## PENDIENTE VALIDAR QUE HACER CUANDO CAMPO "CREAR DIRECTORIO" CONTIENE CUALQUIER VERDURA
            elif [ "$crear_directorio" == "NO" ] && [ $existe_directorio -eq 1 ]; then
                info=$(echo "ATENCION: el usuario $nombre_usuario no pudo ser creado $nombre_usuario")
                cant_usuarios_creados=$((cant_usuarios_creados - 1))   
            fi
        fi    
      
        ##Mostrar info, si "-i" esta presente
        if [ $mostrar_info ]; then
            echo -e $info
        fi
    done
    ##Mostrar la cantidad de usuarios creados con exito
    echo -e "\nSe han creado $cant_usuarios_creados usuarios con éxito."
}


##Funcion para colocarle a cada usuario creado con exito la contraseña pasada como argumento de "-c"
function setear_passwd {
    #archivo de usuario creados con exito
    usuarios_creados="./logs/usuarios_creados.txt"

    if ! [ $set_passwd ]; then
        if [ -z $password ]; then
            echo "No se puede colocar password a los usuarios"
        else
            for i in $(cat $usuarios_creados); do
                echo $i:$password | sudo chpasswd
            done
        fi
    fi
}

##Validar que al menos recibe un parametro
if [ -z "$#" ]; then
    exit 1
fi


##Validacion de parametros pasados al script.

while getopts "ic:" opt; do
    case "$opt" in
        i)
            ##Verificar que se haya pasado el -i como paramentro
            ##Asignar un valor que diga que hay que mostrar la informacion de cada usuario creado
            ## y tambien cuando no pueda crear un usuario
            ##ejemplo: mostrar_info=1
            mostrar_info=true
            echo "hola"
            ;;
        c)
            ##Verificar que se haya pasado el -c como parametro
            ##Asignar un valor que diga que hay que establecer una contraseña para todos los usuarios a crear
            ##Ejemplo, poner_contraseña=1, guardar argumento de la contraseña "password=-p $OPTARG"
            set_passwd=true
            password=$OPTARG
            ;;
        *)
            ##Verificar que no haya ningun comando incorrecto, si lo hay se debe mostrar un mensaje con el error
            ##Asignar un codigo de salida "exit 1"
            echo "Los parametros son incorrectos" >&2
            exit 2
            ;;
    esac 
done

##Al ejecutar getops, nos quedamos con el archivo pasado como parametro en $1
shift $((OPTIND-1))
echo $OPTIND
echo $1

##Verificacion del tipo de archivo
arch=$1
if ! [ -f "$arch" ]; then
    echo "Solo se permiten archivos de tipo file"  >&2
    exit 3
##Verficacion de permiso lectura del archivo
elif ! [ -r $arch ]; then
    echo "el archivo no tiene permisos de lectura" >&2
    exit 4
##Verificacion de archivo no vacio    
elif ! [ -s "$arch" ]; then
    echo "El archivo esta vacio" >&2
    exit 5
  
    
fi

##LLamamos a la funcion "crear_usuarios"
crear_usuarios
setear_passwd









