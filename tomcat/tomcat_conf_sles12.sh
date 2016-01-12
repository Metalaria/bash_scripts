#!/usr/bin/env sh
#Version 2
#Fecha: 07/10/2015
#Autor: Gonzalo Mejias Moreno
#Descripción: El script configura el servidor Tomcat.

#copia de seguridad del los archivo de configuración $DATEes
backup_conf_files() {
		DATE=$(date +%Y%m%d)
        cp -p /etc/tomcat/logging.properties /etc/tomcat/logging.properties.$DATE
        cp -p /etc/tomcat/server.xml /etc/tomcat/server.xml.$DATE
        cp -p /etc/tomcat/log4j.properties /etc/tomcat/log4j.properties.$DATE
        cp -p /usr/share/tomcat/bin/catalina.sh /usr/share/tomcat/bin/catalina.sh.$DATE
}

replace_logs_location_catalina() {
    local search='CATALINA_OUT="$CATALINA_BASE"/logs/catalina.out'
    local replace="CATALINA_OUT=/logs/tomcat/catalina.out"
    sed -i  "s|${search}|${replace}|g" /servicios/tomcat/bin/catalina.sh
}

replace_logs_location_server_xml() {
    local search="logs"
    local replace="/logs/tomcat"
    sed -i  "s|${search}|${replace}|g" /etc/tomcat/server.xml
}

replace_logging_log4j(){
        local search='.R.File=${catalina.home}/logs/tomcat.log'
        local replace="/logs/tomcat/tomcat.log"
        sed -i  "s|${search}|${replace}|g" /etc/tomcat/log4j.properties
}

replace_logging_properties() {
    local search='.FileHandler.directory = ${catalina.base}/logs'
    local replace=".FileHandler.directory = /logs/tomcat"
    sed -i  "s|${search}|${replace}|g"  /etc/tomcat/logging.properties
}

replace_sbin_loggin() {
        local search='${CATALINA_BASE}/logs/catalina.out 2>&1'
        local replace="/logs/tomcat/catalina.out 2>&1"
        sed -i  "s|${search}|${replace}|g" /usr/share/tomcat/bin/catalina.sh
}

replace_catalanina_base(){
	local search='CATALINA_BASE="/usr/share/tomcat"'
	local replace='CATALINA_BASE="/servicios/tomcat"'
	sed -i  "s|${search}|${replace}|g" /etc/tomcat/tomcat.conf
}

replace_catalanina_home(){
	local search='CATALINA_HOME="/usr/share/tomcat"'
	local replace='CATALINA_HOME="/servicios/tomcat"'
	sed -i  "s|${search}|${replace}|g" /etc/tomcat/tomcat.conf
}

replace_tmpdir(){
	local search='CATALINA_TMPDIR="/var/cache/tomcat/temp"'
	local replace='CATALINA_TMPDIR="/servicios/tomcat/temp"'
	sed -i  "s|${search}|${replace}|g" /etc/tomcat/tomcat.conf
	}

replace_shutdown(){
	local search='Server port="8005" shutdown="SHUTDOWN"'
    local replace='Server port="8005" shutdown="NONDETERMINISTICVALUE"'
    sed -i  "s|${search}|${replace}|g" /etc/tomcat/server.xml
}


#Asigna los permisos sobre los archivos de tomcat
permissions_tomcat_user() {
        groupadd tomcat
        chown -R tomcat /servicios/tomcat
        chgrp -R tomcat /servicios/tomcat
        chown -R tomcat /logs/tomcat
        chgrp -R tomcat /logs/tomcat
		chown -R tomcat /etc/tomcat
        chgrp -R tomcat /etc/tomcat
}

#change_autodeploy()

check_status() {
        local resultado_grep=$(systemctl status tomcat.service | grep -c running)
        local timestamp=`date "+%D || %H:%M:%S :"`
        if [ "$resultado_grep" = "1" ]; then
                echo $timestamp "INFO: El servidor Tomcat ha sido configurado correctamente"
        else
                echo $timestamp "INFO: Ha ocurrido un fallo durate la configuración del servidor"
                systemctl status tomcat.service
        fi
}

webapps_directory() {
	test=$(ls -al /servicios/tomcat/ | grep -c /srv/tomcat/webapps)
	timestamp=`date "+%D || %H:%M:%S :"`
	if [ "$test" = "1" ]; then
        unlink /servicios/tomcat/webapps
        mkdir /servicios/tomcat/webapps
        echo $timestamp "INFO: Creado nuevo directorio para webapps"
	else
        echo $timestamp "El directorio para las webapps ya estaba creado previamente"
	fi
}

timestamp=`date "+%D || %H:%M:%S :"`

backup_conf_files
echo $timestamp "INFO: Backup de los archivos de configuración realizado"

#replace_logs_location_catalina
replace_logs_location_server_xml
replace_logging_properties
replace_logging_log4j
replace_sbin_loggin
echo $timestamp "INFO: Cambiado el directorio de almacenamiento de los logs."

permissions_tomcat_user
echo $timestamp "INFO: Permisos cambiados para el usuario tomcat"

cp -r /usr/share/tomcat/* /servicios/tomcat/
#rsync -av --progress --exclude='/usr/share/tomcat/webapps' /usr/share/tomcat/* /servicios/tomcat/
echo $timestamp "INFO: Copiados archivos de /usr/share/tomcat/ a /servicios/tomcat/"

replace_catalanina_base
replace_catalanina_home
replace_tmpdir
echo $timestamp "INFO: Cambiado el directorio por defecto"

rm /servicios/tomcat/lib
ln -s /usr/share/java/tomcat /servicios/tomcat/lib
echo $timestamp "INFO: Actualizado enlace simbólico a java"

webapps_directory

echo $timestamp "INFO: Arrancando el servicio ..."
systemctl restart tomcat.service

check_status

exit 0
