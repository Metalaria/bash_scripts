#!/bin/bash

#Version 1
#Fecha: 22/12/2015
#Autor: Gonzalo Mejías Moreno

#Obtenemos la dirección IP del servidor maestro
master_ip=`mysql --login-path=root -e "show slave status \G;" 2>&1 | grep "Master_Host" | cut -d ":" -f2 | tr -d ' '`

DATE=`date +%Y/%m/%d:%H:%M:%S`
LOG='status_slaves.log'

#obtenemos el bin-log del maestro
binlog_file=`ssh root@$master_ip mysql --login-path=root -e "show master status\G;" 2>&1 | grep "mysql-bin" | cut -d ":" -f2 | tr -d ' '`

#obtenemos la posición del log del maestro
position=`ssh root@$master_ip mysql --login-path=root -e "show master status\G;" 2>&1 | grep "Position" | cut -d ":" -f2 | tr -d ' '`

echo $DATE >> $LOG 2>&1
echo " " >> $LOG 2>&1
echo "************************************************************" >> $LOG 2>&1
echo "*                                                          *" >> $LOG 2>&1
echo "*       Empieza la comprobación de la replicación          *" >> $LOG 2>&1
echo "*                                                          *" >> $LOG 2>&1
echo "************************************************************" >> $LOG 2>&1

check_replication_status(){
        mysql --login-path=root -e "show slave status \G;" 2>&1 | grep "Slave_IO_Running: No"
        mysql --login-path=root -e "show slave status \G;" 2>&1 | grep "Slave_SQL_Running: No"
}

replication_status(){
check_replication_status
        if [ "$?" = "0" ]; then
        echo $DATE "Fallo en la replicación en el esclavo principal" >> $LOG 2>&1
        echo $DATE "Intendo solucionar el problema en el esclavo principal..." >> $LOG 2>&1
                service mysql restart
                        if [ "$?" -ne "1" ]; then
                check_replication_status
                if [ "$?" -ne "1" ]; then
                        mysql --login-path=root -e "CHANGE MASTER TO MASTER_HOST='$master_ip', MASTER_USER='replication_user',MASTER_PASSWORD='slave', MASTER_PORT=3306, MASTER_LOG_FILE='$binlog_file', MASTER_LOG_POS=$position;"
                        mysql --login-path=root -e "start slave;"

                        check_replication_status
                        if [ "$?" -ne "1" ]; then
                                echo $DATE "no se puede levantar el esclavo principal, requiere intervención manual" >> $LOG 2>&1
                        fi
                fi
                        fi
        fi
if [ "$?" = "0" ]; then
        echo $DATE "replicacion funcionando correntamente" >> $LOG 2>&1
fi
}

replication_status
exit 0
