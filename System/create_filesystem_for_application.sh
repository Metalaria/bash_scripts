#!/bin/bash
#Version 5
#Fecha: 21/01/2016
#Autor: Gonzalo Mejías Moreno

echo $1

for i in `ls -1 /sys/class/scsi_host/ | awk -F 'host' '{ print $2 }'`; do 
    echo "- - -" > /sys/class/scsi_host/host${i}/scan
done
	

#Estas variables buscan los discos que tiene la máquina pero que no tienen ninguna partición ni ningún tipo de formato
#disk_one=`lsblk -nfs | grep "^sd" | grep -v "^sda" | cut -d " " -f1,2,3,4 | sed '/^$/d' | sed -n '1p' | tr -d ' '`
#disk_two=`lsblk -nfs | grep "^sd" | grep -v "^sda" | cut -d " " -f1,2,3,4 | sed '/^$/d' | sed -n '2p' | tr -d ' '`
#disk_three=`lsblk -nfs | grep "^sd" | grep -v "^sda" | cut -d " " -f1,2,3,4 | sed '/^$/d' | sed -n '2p' | tr -d ' '`

disks=(`lsblk -nfs | grep "^sd" | grep -v "^sda" | cut -d " " -f1,2,3,4 | sed '/^$/d' | grep -v '[0-9]' | tr -d ' '`)

declare -a empty_array_of_disk=( )

for ((j=1;j<=3;j++)); do
	insert="/dev/"${disks[$j-1]}
	empty_array_of_disk+=($insert)
done

part_number=1

create_disk_apache(){
	#creamos la partición en el disco
	(echo o; echo n; echo p; echo 1; echo ; echo; echo w) | fdisk ${empty_array_of_disk[0]}
	(echo o; echo n; echo p; echo 1; echo ; echo; echo w) | fdisk ${empty_array_of_disk[1]}
	#creamos el volumen en el primer disco
	pvcreate ${empty_array_of_disk[0]}$part_number | tr -d ' '
	pvcreate ${empty_array_of_disk[1]}$part_number | tr -d ' '
        #creamos el volumegroup
        vgcreate apache ${empty_array_of_disk[0]}$part_number | tr -d ' '	
        vgcreate logs_apache ${empty_array_of_disk[1]}$part_number | tr -d ' '
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
        (echo o; echo n; echo p; echo 1; echo ; echo; echo w) | fdisk ${empty_array_of_disk[0]}
	(echo o; echo n; echo p; echo 1; echo ; echo; echo w) | fdisk ${empty_array_of_disk[0]}
	#creamos el volumen en el primer disco
        pvcreate ${empty_array_of_disk[0]}$part_number|tr -d ' '
	pvcreate ${empty_array_of_disk[1]}$part_number | tr -d ' '
        #creamos el volumegroup
        vgcreate tomcat ${empty_array_of_disk[0]}$part_number|tr -d ' '
	vgcreate logs_tomcat ${empty_array_of_disk[1]}$part_number | tr -d ' '
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
        (echo o; echo n; echo p; echo 1; echo ; echo; echo w) | fdisk ${empty_array_of_disk[0]}
	(echo o; echo n; echo p; echo 1; echo ; echo; echo w) | fdisk ${empty_array_of_disk[1]}
	(echo o; echo n; echo p; echo 1; echo ; echo; echo w) | fdisk ${empty_array_of_disk[2]}
	#creamos el volumen en el primer disco
        pvcreate ${empty_array_of_disk[0]}$part_number|tr -d ' '
	pvcreate ${empty_array_of_disk[1]}$part_number | tr -d ' '
	pvcreate ${empty_array_of_disk[2]}$part_number | tr -d ' '
        #creamos el volumegroup
        vgcreate mysql ${empty_array_of_disk[0]}$part_number|tr -d ' '
	vgcreate logs_mysql ${empty_array_of_disk[1]}$part_number | tr -d ' '
	vgcreate backup_mysql ${empty_array_of_disk[2]}$part_number | tr -d ' '
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

create_disks_jboss(){
	#creamos la partición en el disco
	(echo o; echo n; echo p; echo 1; echo ; echo; echo w) | fdisk ${empty_array_of_disk[0]}
	(echo o; echo n; echo p; echo 1; echo ; echo; echo w) | fdisk ${empty_array_of_disk[1]}
	#creamos el volumen en el primer disco
        pvcreate ${empty_array_of_disk[0]}$part_number | tr -d ' '
	pvcreate ${empty_array_of_disk[1]}$part_number | tr -d ' '
        #creamos el volumegroup
        vgcreate jboss ${empty_array_of_disk[0]}$part_number | tr -d ' '
	vgcreate logs_jboss ${empty_array_of_disk[1]}$part_number | tr -d ' '
        #Asignamos el tamaño total
        lvcreate -l100%FREE -n lv_jboss01 jboss
	lvcreate -l100%FREE -n lv_logs_jboss01 logs_jboss
	#Damos formato al disco	
	mkfs.xfs /dev/jboss/lv_jboss01
	mkfs.xfs /dev/logs_jboss/lv_logs_jboss01
	#Creamos el punto de montaje
	mkdir -p /servicios/jboss
	mkdir -p /logs/jboss
	#Añadimos los nuevos puntos de montaje al archivo fstab
	echo "/dev/jboss/lv_jboss01 /servicios/jboss    xfs     defaults        1 2" >> /etc/fstab
	echo "/dev/logs_jboss/lv_logs_jboss01 /logs/jboss    xfs     defaults        1 2" >> /etc/fstab
	#Montamos el nuevo volumen
	mount -a
}

case $1 in
	"apache")
		echo "apache"
		create_disk_apache >> create_filesystem.log 2>&1
		lsblk -f
		df -Th
		exit 0
	;;
	"tomcat")
		create_disk_tomcat >> create_filesystem.log 2>&1
		lsblk -f
		df -Th
		exit 0
	;;
	"mysql")
		create_disk_mysql >> create_filesystem.log 2>&1
		lsblk -f
		df -Th
		exit 0
	;;
	"jboss")
		create_disks_jboss >> create_filesystem.log 2>&1
		lsblk -f
		df -Th
		exit 0
	;;	
	*)
		echo "Opción no válida"
		echo "Las opciones son apache, tomcat, mysql y jboss"
		exit 1
	;;
	esac
