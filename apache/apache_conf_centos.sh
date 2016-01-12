#!/usr/bin/env sh
#Version 1.1
#Fecha: 13/10/2015
#Autor: Gonzalo Mejias Moreno
#Descripción: El script configura el demonio apache2.
#Cambia el directorio del DocumentRoot, el directorio de logs y los servertokens para que de la mínima info posible

#############################
#							              #
#		      CAMBIOS			     	#
#							              #	
#############################

# 13/10/2015
# * Añadidas configuraciones de bastionado
# * Añadida función para cambiar la ubicación del archivo error_log


replace_document_root() {
        local search="var/www"
        local replace="/servicios/apache/www/"
        sed -i  "s|${search}|${replace}|g"  /etc/apache2/default-server.conf
		chown wwwrun -R /servicios/apache/www/
		chgrp www -R /servicios/apache/www/
		chmod o-rwx -R /servicios/apache/www/
}

replace_logs_location() {
        local search="/var/log/apache2"
        local replace="/logs/apache"
        sed -i  "s|${search}|${replace}|g"  /etc/apache2/default-server.conf
		chown wwwrun -R /logs/apache
		chgrp www -R /logs/apache
		chmod o-rwx -R /logs/apache
}

replace_error_log_location(){
	local search="/var/log/apache2/error_log"
	local replace="/logs/apache/error_log"
	sed -i "s|${search}|${replace}|g" /etc/apache2/httpd.conf
}

replace_seclog_location(){
	local search="/var/log/apache2/modsec_audit.log"
	local replace="/logs/apache/modsec_audit.log"
	sed -i "s|${search}|${replace}|g" /etc/apache2/conf.d/mod_security2.conf
}

secure_apache_user(){
	passwd -S wwwrun
}

disable_old_tls_version(){
	local search="NSSProtocol TLSv1.0,TLSv1.1,TLSv1.2"
	local replace="NSSProtocol TLSv1.1,TLSv1.2"
	sed -i "s|${search}|${replace}|g" /etc/apache2/conf.d/mod_nss.conf
}

check_status() {
        local resultado_grep=$(systemctl status apache2.service | grep -c running)
        local timestamp=`date "+%D || %H:%M:%S :"`
        if [ "$resultado_grep" = "1" ]; then
                echo $timestamp "INFO: El servidor Apache ha sido configurado correctamente"
        else
                echo $timestamp "INFO: Ha ocurrido un fallo durate la configuración del servidor"
                systemctl status apache2.service
        fi
}

timestamp=`date "+%D || %H:%M:%S :"`

replace_document_root
echo $timestamp "INFO: Cambiado el directorio por defecto."

replace_logs_location
replace_error_log_location
replace_seclog_location
echo $timestamp "INFO: Cambiado el directorio de almacenamientod de los logs."

sed -i 's/^APACHE_SERVERTOKENS="OS"/APACHE_SERVERTOKENS="Prod"/g' /etc/sysconfig/apache2
echo $timestamp "INFO: Cambiados los servertokens de OS a Prod."

disable_old_tls_version
echo $timestamp "INFO: Desahabilitadas versiones antiguas de TLS."

systemctl restart apache2.service
echo $timestamp "INFO: Servicio apache reiniciado para que recoja los cambios realizados"

echo $timestamp "INFO: Este es el estado del serviocio"
check_status

exit 0

