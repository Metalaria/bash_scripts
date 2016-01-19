#!/bin/sh
# USO: sudo ./mysqlinstall.sh
# Es neseario el ejecutar el script (./mysql_setup.sh) después de instalar

# guardamos el directorio actual
original_working_directory=${PWD}


# Cambiar por la versión que queramos
mysql_latest_version="mysql-5.6.28"
mysql_url="http://dev.mysql.com/get/Downloads/MySQL-5.6/${mysql_latest_version}.tar.gz/from/http://cdn.mysql.com/"

# Directorio de instalación
install_directory="/usr/local/mysql/"

# Descargamos el código fuente
cd
if [ ! -d "downloads/" ]; then
    mkdir downloads
fi
cd downloads
echo "Descargando mysql ..."
lynx "$mysql_url"

# Extraemos el archivo de código
tar zxvf "${mysql_latest_version}.tar.gz" >/dev/null
cd $mysql_latest_version

pwd

# Creamos el usuario y el grupo mysql
groupadd mysql
useradd -r -g mysql mysql

# Configuramos y compilamos
cmake . -DBUILD_CONFIG=mysql_release -DCMAKE_INSTALL_PREFIX=/usr/local/mysql
if [ $? -ne 0 ]; then
    echo "Error durante la configuración"
    exit 1
fi

make
if [ $? -ne 0 ]; then
    exit
fi

# Instalamos
make install
if [ $? -ne 0 ]; then
    echo "Error durante la instalación"
    exit 1
fi


# Volvemos al directorio original
cd $original_working_directory

exit 0
