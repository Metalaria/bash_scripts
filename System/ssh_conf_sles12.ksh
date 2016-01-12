#!/usr/bin/env sh
#Nombre Script: ssh_config_suse12.ksh
#Fecha: 01/10/2015
#Autor:Gonzalo Mejías Moreno
#Descripción: El script configura el demonio sshd

resultado=`grep '^Port ' /etc/ssh/sshd_config`
if [ "$resultado" = "" ]; then
		echo 'Port 3105' >> /etc/ssh/sshd_config
else
	sed -i 's/^Port .*/Port 3105/' /etc/ssh/sshd_config
fi

resultado=`grep '^PermitRootLogin ' /etc/ssh/sshd_config`
if [ "$resultado" = "" ]; then
		echo 'PermitRootLogin no' >> /etc/ssh/sshd_config
else
sed -i 's/^PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config
fi

resultado=`grep '^UseDNS ' /etc/ssh/sshd_config`
if [ "$resultado" = "" ]; then
		echo 'UseDNS no' >> /etc/ssh/sshd_config
else
sed -i 's/^UseDNS .*/UseDNS no/' /etc/ssh/sshd_config
fi

timestamp=`date "+%D || %H:%M:%S :"`
systemctl restart sshd.service
echo $timestamp "INFO: Fichero Configuracion sshd cambiado correctamente."

echo "INFO: El demonio sshd está arrancado"
systemctl status sshd.service

echo "INFO: El demonio sshd está escuchando"
ss -antp | grep 3105 | grep LISTEN

exit 0
