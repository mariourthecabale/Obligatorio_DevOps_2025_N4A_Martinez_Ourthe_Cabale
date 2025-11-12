#!/bin/bash
arch=$1
usuarios_a_crear=$(cat $arch| wc -l)
IFS="
"
 
for i in $(cat $arch); do
        nombre_usuario=$(echo $i | cut -d: -f1)
        descripcion=$(echo $i | cut -d: -f2)
        directorio_home=$(echo $i | cut -d: -f3)
        crear_directorio=$(echo $i| cut -d: -f4)
        shell=$(echo $i | cut -d: -f5)
 
       
       
        ##verificar si agregar shell, o dejarla por defecto
        if [ -z "$shell" ]; then
            shell="/bin/bash"            
        fi
 
        if [ -z "$descripcion" ]; then
            descripcion=""
        fi
 
        if [ "$crear_directorio" == "SI" ]; then
            useradd -c "$descripcion" -m -d "$directorio_home" -s "$shell" "$nombre_usuario"
        elif [ "$crear_directorio" == "NO" ]; then
            useradd -c "$descripcion" -d "$directorio_home" -s "$shell" "$nombre_usuario"
        else
            useradd -c "$descripcion" -s "$shell" "$nombre_usuario"    
        fi
 
        if $? -eq 0; then
            cant_usuarios_creados+=1
            echo $nombre_usuario $descripcion $directorio_home $crear_directorio $shell
        else
            echo "ATENCION: el usuario $nombre_usuario no pudo ser creado"
            exit "algo"      
        fi
        ##comando para agregar usuario
       
done
 
echo "\nSe han creado $cant_usuarios_creados usuarios con éxito."
