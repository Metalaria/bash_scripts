#!/bin/sh
# USO: sudo ./mysql_setup.sh


# Guardamos el directorio actual
original_working_directory=${PWD}

cd /usr/local/mysql

# Asiganamos los permisos
chown -R mysql .
chgrp -R mysql .

scripts/mysql_install_db --user=mysql --basedir=/usr/local/mysql --datadir=/var/lib/mysql           
if [ $? -ne 0 ]; then
    exit
fi

# Asignamos los permisos al directio
chown -R root .
chown -R mysql data    

cd $original_working_directory

exit 0
