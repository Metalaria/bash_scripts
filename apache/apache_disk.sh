#!/bin/bash
#Version 1
#Fecha: 23/12/2015
#Autor: Gonzalo Mejías Moreno

create_disk_apache_data(){
        #creamos el volumen en el primer disco
        (echo o; echo n; echo p; echo 1; echo ; echo; echo w) | fdisk /dev/sdb
        pvcreate -ff /dev/sdb1
        #creamos el volumegroup
        vgcreate apache /dev/sdb1
        #Asignamos el tamaño total
        lvcreate -l100%FREE lv_apache01 apache
#       mkfs.xfs /dev/apache/lv_apache01
}

create_disk_logs_apache(){
        (echo o; echo n; echo p; echo 1; echo ; echo; echo w) | fdisk /dev/sdc
        pvcreate -ff /dev/sdc1
        vgcreate logs_apache /dev/sdc1
        lvcreate -l100%FREE lv_logs_apache01 logs_apache
#       mkfs.xfs /dev/logs_apache/lv_logs_apache01
}

create_disk_apache_data
if [ "$?" = "0" ]; then
        mkfs.xfs /dev/apache/lv_apache01
else
        echo "No se ha podido crear el volumen"
#       exit 0
fi

create_disk_logs_apache
if [ "$?" = "0" ]; then
        mkfs.xfs /dev/logs_apache/lv_logs_apache01
else
        echo "No se ha podido crear el volumen de logs"
#       exit 0
fi

echo "/dev/apache/lv_apache01   /servicios/apache/www/  xfs     defaults        1 2" >> /etc/fstab
echo "/dev/logs_apache/lv_logs_apache01 /logs/apache    xfs     defaults        1 2" >> /etc/fstab

mkdir -p /servicios/apache/www/
mkdir -p /logs/apache

mount -a

lsblk -f

exit 0
