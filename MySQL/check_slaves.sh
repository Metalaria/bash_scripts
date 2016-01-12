#!/bin/bash

#Version 1
#Fecha: 22/12/2015
#Autor: Gonzalo Mejías Moreno

check_ip(){
        ip="$i"
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

#check_connection(){
#	nmap -p 3306 -sT $ip 2>&1 | grep open
#	if [ "$?" = "0" ]
#	fi
#}

for i do
        check_ip
		echo "Comprobando servidor ..."
#check_connection
        ssh root@$ip /root/check_slave.sh
		echo "Comprobación terminada"
		echo " "
done

exit 0
