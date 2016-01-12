#!/usr/bin/env sh
#Version 1
#Fecha: 06/10/2015
#Autor: Gonzalo Mejias Moreno
#Descripción: El script configura el servidor Tomcat a partir del binario descomprimido

#copia de seguridad del los archivo de configuración originales
cp -p /servicios/tomcat/bin/catalina.sh /servicios/tomcat/bin/catalina.sh.Original
cp -p /servicios/tomcat/conf/logging.properties /servicios/tomcat/conf/logging.properties.original

#renombra el binario de java
#mv /servicios/java/jdk* /servicios/java/jdk

replace_logs_location_catalina() {
    local search='CATALINA_OUT="$CATALINA_BASE"/logs/catalina.out'
    local replace="CATALINA_OUT=/logs/tomcat/catalina.out"
    sed -i  "s|${search}|${replace}|g" /servicios/tomcat/bin/catalina.sh
}

replace_logs_location_server_xml() {
    local search="logs"
    local replace="/logs/tomcat"
    sed -i  "s|${search}|${replace}|g" /servicios/tomcat/conf/server.xml
}

replace_logging_properties() {
    local search='.AsyncFileHandler.directory = ${catalina.base}/logs'
    local replace=".AsyncFileHandler.directory = /logs/tomcat"
    sed -i  "s|${search}|${replace}|g"  /servicios/tomcat/conf/logging.properties
}

create_autostart_script() {
    cat script_inicio.txt > /servicios/tomcat/bin/tomcat_autostart.sh
    chmod +x /servicios/tomcat/bin/tomcat_autostart.sh
}

#crea el usuario tomcat y le de da los permisos sobre los archivos de tomcat
create_tomcat_user() {
        mkdir /home/tomcat
        useradd tomcat
        groupadd tomcat
        useradd -c "Tomcat" -u 91 -g tomcat -s /bin/sh -r tomcat
        chown -R tomcat /servicios/tomcat
        chgrp -R tomcat /servicios/tomcat
		chown -R tomcat /logs/tomcat
        chgrp -R tomcat /logs/tomcat
}
timestamp=`date "+%D || %H:%M:%S :"`

replace_logs_location_catalina
replace_logs_location_server_xml
replace_logging_properties
echo $timestamp "INFO: Cambiado el directorio de almacenamiento de los logs."

create_autostart_script
echo $timestamp "INFO: Creado script de inicio, reinicio y parada de tomcat en /servicios/tomcat/bin/tomcat_autostart.sh"

create_tomcat_user
echo $timestamp "INFO: El usuario tomcat ha sido creado y se le han dado permisos sobre los archivos del servidor"

echo $timestamp "INFO: Arrancando el servicio ..."
/servicios/tomcat/bin/tomcat_autostart.sh start

echo $timestamp "INFO: El estado del servidor tomcat es: "
/servicios/tomcat/bin/tomcat_autostart.sh status

exit 0
