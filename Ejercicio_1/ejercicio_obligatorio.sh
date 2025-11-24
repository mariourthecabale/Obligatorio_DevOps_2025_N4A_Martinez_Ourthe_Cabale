#!/bin/bash

##Definimos variables globales
mostrar_info=false
password=""
existe_directorio=""
set_passwd=false
IFS="
"
mostrar_info=True
creado=""
linea_ok=""

##Función para ver si un usuario fue creado con exito
function usuario_creado {
    if [ $creado -eq 0 ]; then
        echo "$nombre_usuario" >> "./logs/usuarios_creados.txt"
        cant_usuarios_creados=$((cant_usuarios_creados + 1))
    else
        info="Usuario $nombre_usuario ya existe"
    fi  
}

##Función para crear usuarios
function crear_usuarios {
    usuarios_a_crear=$(cat $arch| wc -l)
    cant_usuarios_creados=0
    for i in $(cat $arch); do
        nombre_usuario=$(echo $i | cut -d: -f1)
        descripcion=$(echo $i | cut -d: -f2)
        directorio_home=$(echo $i | cut -d: -f3)
        crear_directorio=$(echo $i| cut -d: -f4)
        shell=$(echo $i | cut -d: -f5)
        
        ##Chequeo de que la linea a leer tenga los campos requeridos
        
        
       
        ##Verificar si agregar shell, o dejarla por defecto
        if [ -z "$shell" ]; then
            shell="/bin/bash"            
	    elif ! (grep -q $shell /etc/shells); then
            shell="/bin/bash"
        fi
        ##Evaluamos si el directorio existe, si no existe se le asigna el por defecto en caso que luego haya que crearlo.
        if [ -d "$directorio_home" ]; then
            existe_directorio=$(echo "$?")
        elif [ -z $directorio_home ]; then
            existe_directorio="1"
            directorio_home="/home/$nombre_usuario"
        else  
            existe_directorio="1"
        fi

        ##Definimos la info por defecto a mostrar, en caso de que sea necesaria cambiarla por error al crear el usuario se cambiará su valor
        info=$(echo "Usuario $nombre_usuario creado con exito con datos indicados:\n\tComentario: $descripcion\n\tDir home: $directorio_home\n\tAsegurado existencia de directorio home: $crear_directorio\n\tShell por defecto: $shell") 
        
        ##Validando nombre de usuario.
        if [ -z $nombre_usuario ]; then
            info="Campo nombre de usuario invalido, se encuentra vacío"
        fi


        if [ -z $crear_directorio ]; then
            crear_directorio="SI"
        elif ! [[ ($crear_directorio="SI") || ($crear_directorio="NO") ]]; then
            info="El usuario $nombre_usuario no puede ser creado, campo crear directorio no es valido."
        fi


    

        
        if (echo $i | egrep -q ^.+:.*:.*:.*:.*$); then
            ##Evaluamos si descripción esta vacía o no
            if ! [ -z $descripcion ]; then
                ##Crear directorio si no existe y colocar el usuario dentro del mismo
                if [[ ("$crear_directorio" == "SI" && $existe_directorio -eq 1 && $linea_ok=0) ]]; then
                    useradd -c "$descripcion" -m -d "$directorio_home" -s "$shell" "$nombre_usuario" 2>/dev/null
                    creado=$(echo "$?")
                    usuario_creado
                ##Agregar usuario a directorio existente
                elif [[ ("$crear_directorio" == "NO" && $existe_directorio -eq 0) || ("$crear_directorio" == "SI" &&  $existe_directorio -eq 0) || (-z "$crear_directorio" && $existe_directorio -eq 0) ]]; then
                    useradd -c "$descripcion" -d "$directorio_home" -s "$shell" "$nombre_usuario" 2>/dev/null
                    creado=$(echo "$?")
                    usuario_creado
                ##Crear directorio home por defecto, si campo "crear_directorio" está vacío.
                elif [[ (-z "$crear_directorio" && $existe_directorio -eq 1) ]]; then
                    useradd -c "$descripcion" -s "$shell" "$nombre_usuario" 2>/dev/null
                    creado=$(echo "$?")
                    usuario_creado
                ##No se puede crear usuario
                elif [ "$crear_directorio" == "NO" ] && [ $existe_directorio -eq 1 ]; then
                    info=$(echo "ATENCION: el usuario $nombre_usuario no pudo ser creado")
                fi
            else
                #Crear directorio si no existe y colocar el usuario dentro del mismo
                if [[ ("$crear_directorio" == "SI" && $existe_directorio -eq 1) ]]; then
                    useradd -m -d "$directorio_home" -s "$shell" "$nombre_usuario" 2>/dev/null
                    creado=$(echo "$?")
                    usuario_creado
                ##Agregar usuario a directorio existente
                elif [[ ("$crear_directorio" == "NO" && $existe_directorio -eq 0) || ("$crear_directorio" == "SI" &&  $existe_directorio -eq 0) || (-z "$crear_directorio" && $existe_directorio -eq 0) ]]; then
                    useradd -d "$directorio_home" -s "$shell" "$nombre_usuario" 2>/dev/null
                    creado=$(echo "$?")
                    usuario_creado
                ##Crear directorio home por defecto, si campo "crear_directorio" está vacío.
                elif [[ (-z "$crear_directorio" && $existe_directorio -eq 1) ]]; then
                    useradd -s "$shell" "$nombre_usuario" 
                    creado=$(echo "$?")
                    usuario_creado
                ##No se puede crear usuario
                ######## PENDIENTE VALIDAR QUE HACER CUANDO CAMPO "CREAR DIRECTORIO" CONTIENE CUALQUIER VERDURA
                elif [ "$crear_directorio" == "NO" ] && [ $existe_directorio -eq 1 ]; then
                    info=$(echo "ATENCION: el usuario $nombre_usuario no pudo ser creado $nombre_usuario")  
                fi
            fi
        elif ! [ -z $nombre_usuario ]; then
            info="El usuario $nombre_usuario no puede ser creado ya que la linea no cumple con la cantidad de campos solicitados"
        fi      
      
        ##Mostrar info, si "-i" esta presente
        if [ $mostrar_info = "true" ]; then
            echo -e "$info\n"
        fi
    done
    ##Mostrar la cantidad de usuarios creados con exito
    echo -e "\nSe han creado $cant_usuarios_creados usuarios con éxito."
}

##Función para colocarle a cada usuario creado con exito la contraseña pasada como argumento de "-c"
function setear_passwd {
    #Archivo de usuario creados con exito
    usuarios_creados="./logs/usuarios_creados.txt"

    if [ $set_passwd ]; then
        for i in $(cat $usuarios_creados); do
            echo $i:$password | sudo chpasswd
        done
    fi
    echo "" > "./logs/usuarios_creados.txt"
}

##Validar que al menos recibe un parámetro
if [ "$#" -eq 0 ]; then
    echo "Ingrese parametros"
    exit 1    
fi

##Validación de parámetros pasados al script.

while getopts "ic:" opt; do
    case "$opt" in
        i)
            ##Verificar que se haya pasado el -i como parámentro
            ##Asignar un valor que diga que hay que mostrar la información de cada usuario creado
            ## y tambien cuando no pueda crear un usuario
            ##ejemplo: mostrar_info=1
            mostrar_info=true
            ;;
        c)
            ##Verificar que se haya pasado el -c como parametro
            ##Asignar un valor que diga que hay que establecer una contraseña para todos los usuarios a crear
            ##Ejemplo, poner_contraseña=1, guardar argumento de la contraseña "password=-p $OPTARG"
            password=$OPTARG
            setear_passwd=true          
            ;;
        *)
            ##Verificar que no haya ningun comando incorrecto, si lo hay se debe mostrar un mensaje con el error
            ##Asignar un codigo de salida "exit 1"
            echo "Los parametros son incorrectos" >&2
            exit 2
            ;;
    esac 
done

##Al ejecutar getops, nos quedamos con el archivo pasado como parametro en "$1"
shift $((OPTIND - 1))
##Verificación del tipo de archivo
#echo $1
arch=$1
if ! [ -f "$arch" ]; then
    echo "Solo se permiten archivos de tipo file"  >&2
    exit 3
##Verficación de permiso lectura del archivo
elif ! [ -r $arch ]; then
    echo "el archivo no tiene permisos de lectura" >&2
    exit 4
##Verificación de archivo no vacío    
elif ! [ -s "$arch" ]; then
    echo "El archivo esta vacio" >&2
    exit 5
      
fi

##Llamamos a la función "crear_usuarios"
crear_usuarios
setear_passwd
