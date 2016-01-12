#!/bin/bash

#Version 1
#Fecha: 17/12/2015
#Autor: Gonzalo Mejías Moreno
#Descripción: El script comprueba que el servidor maestro está levantado y escuchando por el puerto 3306. Si no lo está
#intenta levantar el maestro y ejecuta en el maestro el script para comprobar el estado de los esclavos. 
#El script requiere que esté instalado el paquete nmap para poder comprobar que esté escuchando el maestro en ese puerto.

DATE=`date +%Y/%m/%d:%H:%M:%S`
LOG='status_master.log'

ip=(`cat master_ip.txt`)

echo $DATE >> $LOG 2>&1
echo " " >> $LOG 2>&1
echo "************************************************************" >> $LOG 2>&1
echo "*                                                          *" >> $LOG 2>&1
echo "*      Empieza la comprobación del servidor maestro        *" >> $LOG 2>&1
echo "*                                                          *" >> $LOG 2>&1
echo "************************************************************" >> $LOG 2>&1

check_master_status(){
	nmap -p 3306 -sT $ip 2>&1 | grep open
}

failover_master(){
check_master_status

if [ "$?" = "1" ]; then
        echo $DATE "Fallo en el servidor maestro" >> $LOG 2>&1
        echo $DATE "Intendo solucionar el problema..." >> $LOG 2>&1
#ssh root@172.18.158.171 service mysql restart
        if [ "$?" -ne "0" ]; then
                check_master_status
                if [ "$?" = "0" ]; then
                        ssh root@$ip ./slave_status.sh
                fi
				if [ "$?" = "1" ]; then
                                echo $DATE "No se puede levantar el maestro, requiere intervención manual" >> $LOG 2>&1
                fi
        fi
fi

if [ "$?" = "0" ]; then
        echo $DATE "servidor maestro funcionando correctamente" >> $LOG 2>&1
fi
}

failover_master
	
exit 0
