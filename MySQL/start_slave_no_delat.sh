#!/bin/bash

#master_ip=`mysql --login-path=slave_status -e "show slave status \G;" 2>&1 | grep "Master_Host" | cut -d ":" -f2 | tr -d ' '`

ip=$1
	
master_bin_log=`mysql --login-path=check_master -e "show master status\G;" 2>&1 |grep "mysql-bin" | cut -d ":" -f2 | tr -d ' '`
master_position=`mysql --login-path=check_master -e "show master status\G;" 2>&1 | grep "Position" | cut -d ":" -f2 | tr -d ' '`

check_ip(){

if expr "$ip" : '[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$' >/dev/null; then
	for i in 1 2 3 4; do
		if [ $(echo "$ip" | cut -d. -f$i) -gt 255 ]; then
			echo "Dirección IP no válida: ($ip)"
			exit 1
		fi
	done
	echo "Dirección IP correcta ($ip)"
	else
		echo "Lo que ha introducido no es una dirección IP: ($ip)"
		exit 1
	fi

}

start_slave(){
	mysql --login-path=root -e "CHANGE MASTER TO MASTER_HOST='$ip',MASTER_DELAY=300, MASTER_USER='slave_user',MASTER_PASSWORD='slave01', MASTER_PORT=3306, MASTER_LOG_FILE='$master_bin_log', MASTER_LOG_POS=$master_position;"
	mysql --login-path=root -e "start slave;"
}

check_ip
start_slave

if [ "$?" -ne "1" ]; then
	echo "Esclavo arrancado correctamente"
else
	echo "Fallo al arrancar la replicación"
fi

exit 0
