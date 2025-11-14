#!/bin/bash
arch=$1
cant_usuarios_creados=$(cat $arch| wc -l)
existe_directorio=""
IFS="
"
mostrar_info=True
for i in $(cat $arch); do
        nombre_usuario=$(echo $i | cut -d: -f1)
        descripcion=$(echo $i | cut -d: -f2)
        directorio_home=$(echo $i | cut -d: -f3)
        crear_directorio=$(echo $i| cut -d: -f4)
        shell=$(echo $i | cut -d: -f5)

        info=$(echo "Usuario $nombre_usuario creado con exito con datos indicados:\n\tComentario: $descripcion\n\tDir home: $directorio_home\n\tAsegurado existencia de directorio home: $crear_directorio\n\tShell por defecto: $shell") 
       
        ##verificar si agregar shell, o dejarla por defecto
        if [ -z "$shell" ]; then
            shell="/bin/bash"            
        fi
 
        if [ -z "$descripcion" ]; then
            descripcion=""
        fi
 

        ##Crear directorio 
        if [ -d "$directorio_home" ]; then
            existe_directorio=$(echo $?)
            #echo $existe_directorio
        else
            existe_directorio=$(echo $?)
            #echo $existe_directorio
        fi


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
        

        ##comando para agregar usuario
done
 
echo -e "\nSe han creado $cant_usuarios_creados usuarios con éxito."
