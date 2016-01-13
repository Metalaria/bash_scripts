#!/bin/bash
#Version 3
#Fecha: 13/01/2016
#Autor: Gonzalo Mejías Moreno

echo $1
#Este bucle reescanea el bus scsci en busca de los nuevos discos, para permitir 
for i in `ls -1 /sys/class/scsi_host/ | awk -F 'host' '{ print $2 }'`; do 
                echo "- - -" > /sys/class/scsi_host/host${i}/scan
done

#Estas variables buscan los discos que tiene la máquina pero que no tienen ninguna partición ni ningún tipo de formato
disk_one=`lsblk -fs | cut -d " " -f1,2,3,4 | sed '/^$/d' | grep -v vg* | grep -v sda | grep -v "NAME" | grep -v "sr0" | head -n 1 | tr -d ' '`
disk_two=`lsblk -fs | cut -d " " -f1,2,3,4 | sed '/^$/d' | grep -v vg* | grep -v sda | grep -v "NAME" | grep -v "sr0" | sed -n '2p' | tr -d ' '`
disk_three=`lsblk -fs | cut -d " " -f1,2,3,4 | sed '/^$/d' | grep -v vg* | grep -v sda | grep -v "NAME" | grep -v "sr0" | head -n 3 | grep -v "$disk_one" | grep -v "$disk_two" | tr -d ' '`

part_number=1

create_disk_apache(){
		#creamos la partición en el disco
        (echo o; echo n; echo p; echo 1; echo ; echo; echo w) | fdisk /dev/$disk_one
		(echo o; echo n; echo p; echo 1; echo ; echo; echo w) | fdisk /dev/$disk_two
		#creamos el volumen en el primer disco
        pvcreate /dev/$disk_one$part_number | tr -d ' '
		pvcreate /dev/$disk_two$part_number | tr -d ' '
        #creamos el volumegroup
        vgcreate apache /dev/$disk_one$part_number | tr -d ' '
		vgcreate logs_apache /dev/$disk_two$part_number | tr -d ' '
        #Asignamos el tamaño total
        lvcreate -l100%FREE -n lv_apache01 apache
		lvcreate -l100%FREE -n lv_logs_apache01 logs_apache
		#Damos formato al disco	
		mkfs.xfs /dev/apache/lv_apache01
		mkfs.xfs /dev/logs_apache/lv_logs_apache01
		#Creamos el punto de montaje
		mkdir -p /servicios/apache
		mkdir -p /logs/apache
		#Añadimos los nuevos puntos de montaje al archivo fstab
		echo "/dev/apache/lv_apache01 /servicios/apache    xfs     defaults        1 2" >> /etc/fstab
		echo "/dev/logs_apache/lv_logs_apache01 /logs/apache    xfs     defaults        1 2" >> /etc/fstab
		#Montamos el nuevo volumen
		mount -a
}


create_disk_tomcat(){
		#creamos la partición en el disco
        (echo o; echo n; echo p; echo 1; echo ; echo; echo w) | fdisk /dev/$disk_one
		(echo o; echo n; echo p; echo 1; echo ; echo; echo w) | fdisk /dev/$disk_two
		#creamos el volumen en el primer disco
        pvcreate /dev/$disk_one$part_number|tr -d ' '
		pvcreate /dev/$disk_two$part_number | tr -d ' '
        #creamos el volumegroup
        vgcreate tomcat /dev/$disk_one$part_number|tr -d ' '
		vgcreate logs_tomcat /dev/$disk_two$part_number | tr -d ' '
        #Asignamos el tamaño total
        lvcreate -l100%FREE -n lv_tomcat01 tomcat
		lvcreate -l100%FREE -n lv_logs_tomcat01 logs_tomcat
		#Damos formato al disco	
		mkfs.xfs /dev/tomcat/lv_tomcat01
		mkfs.xfs /dev/logs_tomcat/lv_logs_tomcat01
		#Creamos los puntos de montaje
		mkdir -p /servicios/tomcat
		mkdir -p /logs/tomcat
		#Añadimos los nuevos puntos de montaje al archivo fstab
		echo "/dev/tomcat/lv_tomcat01   /servicios/tomcat  xfs     defaults        1 2" >> /etc/fstab
		echo "/dev/logs_tomcat/lv_logs_tomcat01 /logs/tomcat    xfs     defaults        1 2" >> /etc/fstab
		#Montamos los nuevos volúmenes
		mount -a
}


create_disk_mysql(){
		#creamos la partición en el disco
        (echo o; echo n; echo p; echo 1; echo ; echo; echo w) | fdisk /dev/$disk_one
		(echo o; echo n; echo p; echo 1; echo ; echo; echo w) | fdisk /dev/$disk_two
		(echo o; echo n; echo p; echo 1; echo ; echo; echo w) | fdisk /dev/$disk_three
		#creamos el volumen en el primer disco
        pvcreate /dev/$disk_one$part_number|tr -d ' '
		pvcreate /dev/$disk_two$part_number | tr -d ' '
		pvcreate /dev/$disk_three$part_number | tr -d ' '
        #creamos el volumegroup
        vgcreate mysql /dev/$disk_one$part_number|tr -d ' '
		vgcreate logs_mysql /dev/$disk_two$part_number | tr -d ' '
		vgcreate backup_mysql /dev/$disk_three$part_number | tr -d ' '
        #Asignamos el tamaño total
        lvcreate -l100%FREE -n lv_mysql01 mysql
		lvcreate -l100%FREE -n lv_logs_mysql01 logs_mysql
		lvcreate -l100%FREE -n lv_bakcup_mysql01 backup_mysql
		#Damos formato al disco	
		mkfs.xfs /dev/mysql/lv_mysql01
		mkfs.xfs /dev/logs_mysql/lv_logs_mysql01
		mkfs.xfs /dev/backup_mysql/lv_bakcup_mysql01
		#Creamos los puntos de montaje
		mkdir -p /bd/mybd1
		mkdir -p /bd/mylog
		mkdir -p /bd/mybackup
		#Añadimos los nuevos puntos de montaje al archivo fstab
		echo "/dev/mysql/lv_mysql01     /bd/mybd1       xfs    defaults        1 2" >> /etc/fstab
		echo "/dev/logs_mysql/lv_logs_mysql01    /bd/mylog       xfs    defaults        1 2" >> /etc/fstab
		echo "/dev/backup_mysql/lv_bakcup_mysql01    /bd/mybackup       xfs    defaults        1 2" >> /etc/fstab
		#Montamos los nuevos volúmenes
		mount -a
}


case $1 in
	"apache")
		echo "apache"
		create_disk_apache
		lsblk -f
		df -Th
		exit 0
	;;
	"tomcat")
		create_disk_tomcat
		lsblk -f
		df -Th
		exit 0
	;;
	"mysql")
		create_disk_mysql
		lsblk -f
		df -Th
		exit 0
	;;
	*)
		echo "Opción no válida"
		exit 1
	;;
	esac
