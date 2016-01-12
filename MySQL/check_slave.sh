#!/bin/bash
#Version 1
#Fecha: 11/12/2015
#Autor: Gonzalo Mejías Moreno
#Descripción: El script comprueba que la replicación está funcionando en el esclavo, de no ser así reinicia el servidor y
# trata de configurar de nuevo la misma. Si no lo consigue imprime un mensaje para pedir una intervención manual.


PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

DATE=`date +%Y/%m/%d:%H:%M:%S`
LOG='status_slaves.log'

function echo_log {
    echo $DATE " : " '!-1' >> $LOG 2>&1
}

echo $DATE >> $LOG 2>&1
echo " " >> $LOG 2>&1
echo "************************************************************" >> $LOG 2>&1
echo "*                                                          *" >> $LOG 2>&1
echo "*    Empieza la comprobación de los servidores esclavo     *" >> $LOG 2>&1
echo "*                                                          *" >> $LOG 2>&1
echo "************************************************************" >> $LOG 2>&1

check_status_slave2(){
        mysql --login-path=slave_status -e "show slave status \G;" 2>&1 | grep "Slave_IO_Running: No"
        mysql --login-path=slave_status -e "show slave status \G;" 2>&1 | grep "Slave_SQL_Running: No"
}

check_main_slave(){
         mysql --login-path=main_slave -e "show slave status \G;" 2>&1 | grep "Slave_IO_Running: No"
         mysql --login-path=main_slave -e "show slave status \G;" 2>&1 | grep "Slave_SQL_Running: No"
}

status=`mysql --login-path=slave_status -e "show slave status \G;" 2>&1 | grep "Slave_IO_Running: No"`

#obtenemos el bin-log del maestro
binlog_file=`mysql --login-path=root -e "show master status\G;" 2>&1 | grep "mysql-bin" | cut -d ":" -f2`

#obtenemos la posición del log del maestro
position=`mysql --login-path=root -e "show master status\G;" 2>&1 | grep "Position" | cut -d ":" -f2`
	
slave2(){

#$status
check_status_slave2

#echo $?

if [ "$?" -ne "1" ]; then
        echo date +%Y/%m/%d:%H:%M:%S "Fallo en la replicación en el esclavo secundario" >> $LOG 2>&1
        echo $DATE "Intendo solucionar el problema en el esclavo secundario..." >> $LOG 2>&1
        ssh root@172.18.158.164 service mysql restart
        if [ "$?" -ne "1" ]; then
        #       $status
                check_status_slave2
                if [ "$?" -ne "1" ]; then
                        ssh root@172.18.158.164 mysql --login-path=root -e "CHANGE MASTER TO MASTER_HOST='172.18.158.171',MASTER_DELAY=300,MASTER_USER='secondary', MASTER_PASSWORD='password', MASTER_PORT=3306, MASTER_LOG_FILE='$binlog_file', MASTER_LOG_POS=$position;"
                        ssh root@172.18.158.164 mysql --login-path=root -e "start slave;"
                        #$status
                        check_status_slave2
                        if [ "$?" -ne "1" ]; then
                                echo $DATE "No se puede levantar el esclavo secundario, requiere intervención manual" >> $LOG 2>&1
                        fi
                fi
        fi
fi

if [ "$?" -ne "1" ]; then
        echo $DATE "Replicación funcionando correntamente en el esclavo secundario" >> $LOG 2>&1
fi
}

main_slave(){

        #$status
check_main_slave

#echo $?

if [ "$?" -ne "1" ]; then
        echo $DATE "Fallo en la replicación en el esclavo principal" >> $LOG 2>&1
        echo $DATE "Intendo solucionar el problema en el esclavo principal..." >> $LOG 2>&1
        ssh root@172.18.158.167 service mysql restart
        if [ "$?" -ne "1" ]; then
        #       $status
                check_main_slave
                if [ "$?" -ne "1" ]; then
                        ssh root@172.18.158.167 mysql --login-path -e "CHANGE MASTER TO MASTER_HOST='172.18.158.171', MASTER_USER='replication_user',MASTER_PASSWORD='slave', MASTER_PORT=3306, MASTER_LOG_FILE='$binlog_file', MASTER_LOG_POS=$position;"
                        ssh root@172.18.158.167 mysql --login-path=root -e "start slave;"
                        #$status
                        check_main_slave
                        if [ "$?" -ne "1" ]; then
                                echo $DATE "no se puede levantar el esclavo principal, requiere intervención manual" >> $LOG 2>&1
                        fi
                fi
        fi
fi

if [ "$?" -ne "1" ]; then
        echo $DATE "replicacion funcionando correntamente en el esclavo principal" >> $LOG 2>&1
fi
}


slave2
main_slave

echo " " >> $LOG 2>&1
exit 0
