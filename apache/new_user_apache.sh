#!/bin/bash
# USO: sudo ./newuser.sh <username>
#Autor: Gonzalo Mejias Moreno

if [ $# -eq 0 ]; then
    read -p "Username? " username
fi

read -p "email? " email
read -p "Nombre completo? " full_name
read -p "Teléfono? " home_phone
read -p "Grupo principal? " init_group
read -p "Grupos adicionales (separados por comas)? " additional_groups


# Agregamos el usuario
if [ ${#additional_groups} -gt 0 ]; then
    useradd -m -g "$init_group" -G "$additional_groups" -s /bin/bash "$username"
else
    useradd -m -g "$init_group" -s /bin/bash "$username"
fi

# Generamos la contraseña del usuario
# Si generamos la contraseña aleatoriamente
read -n1 -p "Contraseña aleatoria? [y/n] " yn_random_password; echo   
if [ $yn_random_password == y ]; then
    # Leemos 12 caracteres que encajan con los requisitos de complejidad de /dev/urandom
    new_password=`tr -cd "[:lower:][:upper:][:digit:]$%" < /dev/urandom | head -c${1:-12}; echo`

else
    read -p "Contraseña? " new_password
fi

echo -e "$new_password\n$new_password" | (passwd $username) >/dev/null
new_password="nada"

# Actualizamos la info
if [ ${#home_phone} -gt 0 ]; then
    chfn -f "$full_name" -h "$home_phone" "$username"
else
    chfn -f "$full_name" "$username"
fi

# Creamos los directorios necesarios
read -n 1 -p "Añadimos el directorio public_html= [y/n]? " yn_pub_html; echo
[ $yn_pub_html == y ] && mkdir -p "/home/${username}/public_html" && echo "Es necesario actualizar el httpd.conf para permitir el directorio del usuario $username"
read -n 1 -p "Add cgi-bin [y/n]? " yn_cgi_bin; echo
[ $yn_cgi_bin == y ] && mkdir -p "/home/${username}/public_html" && echo "Es necesario actualizar el httpd.conf para permitir el directorio del usuario cgi-bin para $username"

exit 0
