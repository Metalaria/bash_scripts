#!/bin/bash
#Version 2
#Fecha: 23/12/2015
#Autor: Gonzalo Mejías Moreno

#echo "¿Servicio a configurar?"
#read servicio
#echo $servicio

echo $1

create_disk_apache_data(){
		#creamos la partición en el disco
        (echo o; echo n; echo p; echo 1; echo ; echo; echo w) | fdisk /dev/sdb
		#creamos el volumen en el primer disco
        pvcreate /dev/sdb1
        #creamos el volumegroup
        vgcreate apache /dev/sdb1
        #Asignamos el tamaño total
        lvcreate -l100%FREE -n lv_apache01 apache
		#Damos formato al disco	
		mkfs.xfs /dev/apache/lv_apache01
		#Creamos el punto de montaje
		mkdir -p /servicios/apache
		#Añadimos los nuevos puntos de montaje al archivo fstab
		echo "/dev/apache/lv_apache01 /servicios/apache    xfs     defaults        1 2" >> /etc/fstab
		#Montamos el nuevo volumen
		mount -a
}

create_disk_logs_apache(){
		#creamos la partición en el disco
        (echo o; echo n; echo p; echo 1; echo ; echo; echo w) | fdisk /dev/sdc
		#creamos el volumen en el primer disco
        pvcreate /dev/sdc1
		#creamos el volumegroup
        vgcreate logs_apache /dev/sdc1
		#Asignamos el tamaño total
        lvcreate -l100%FREE -n lv_logs_apache01 logs_apache
		#Damos formato al disco	
		mkfs.xfs /dev/logs_apache/lv_logs_apache01
		#Creamos el punto de montaje
		mkdir -p /logs/apache
		#Añadimos los nuevos puntos de montaje al archivo fstab
		echo "/dev/logs_apache/lv_logs_apache01 /logs/apache    xfs     defaults        1 2" >> /etc/fstab
		#Montamos el nuevo volumen
		mount -a
}

create_disk_tomcat_data(){
		#creamos la partición en el disco
        (echo o; echo n; echo p; echo 1; echo ; echo; echo w) | fdisk /dev/sdb
		#creamos el volumen en el primer disco
        pvcreate /dev/sdb1
        #creamos el volumegroup
        vgcreate tomcat /dev/sdb1
        #Asignamos el tamaño total
        lvcreate -l100%FREE -n lv_tomcat01 tomcat
		#Damos formato al disco	
		mkfs.xfs /dev/tomcat/lv_tomcat01
		#Creamos los puntos de montaje
		mkdir -p /servicios/tomcat
		#Añadimos los nuevos puntos de montaje al archivo fstab
		echo "/dev/tomcat/lv_tomcat01   /servicios/tomcat  xfs     defaults        1 2" >> /etc/fstab
		#Montamos los nuevos volúmenes
		mount -a
}

create_disk_logs_tomcat(){
		#creamos la partición en el disco
        (echo o; echo n; echo p; echo 1; echo ; echo; echo w) | fdisk /dev/sdc
		#creamos el volumen en el primer disco
        pvcreate /dev/sdc1
		#creamos el volumegroup
        vgcreate logs_tomcat /dev/sdc1
		#Asignamos el tamaño total
        lvcreate -l100%FREE -n lv_logs_tomcat01 logs_tomcat
		#Damos formato al disco	
		mkfs.xfs /dev/logs_tomcat/lv_logs_tomcat01
		#Creamos el punto de montaje
		mkdir -p /logs/tomcat
		#Añadimos los nuevos puntos de montaje al archivo fstab
		echo "/dev/logs_tomcat/lv_logs_tomcat01 /logs/tomcat    xfs     defaults        1 2" >> /etc/fstab
		#Montamos el nuevo volumen
		mount -a
}

create_disk_mysql_data(){
		#creamos la partición en el disco
        (echo o; echo n; echo p; echo 1; echo ; echo; echo w) | fdisk /dev/sdb
		#creamos el volumen en el primer disco
        pvcreate /dev/sdb1
        #creamos el volumegroup
        vgcreate mysql /dev/sdb1
        #Asignamos el tamaño total
        lvcreate -l100%FREE -n lv_mysql01 mysql
		#Damos formato al disco	
		mkfs.xfs /dev/mysql/lv_mysql01
		#Creamos los puntos de montaje
		mkdir -p /bd/mybd1
		#Añadimos los nuevos puntos de montaje al archivo fstab
		echo "/dev/mysql/lv_mysql01     /bd/mybd1       xfs    defaults        1 2" >> /etc/fstab
		#Montamos los nuevos volúmenes
		mount -a
}

create_disk_mysql_logs(){
		#creamos la partición en el disco
        (echo o; echo n; echo p; echo 1; echo ; echo; echo w) | fdisk /dev/sdc
		#creamos el volumen en el primer disco
        pvcreate /dev/sdc1
        #creamos el volumegroup
        vgcreate logs_mysql /dev/sdc1
        #Asignamos el tamaño total
        lvcreate -l100%FREE -n lv_logs_mysql01 logs_mysql
		#Damos formato al disco	
		mkfs.xfs /dev/logs_mysql/lv_logs_mysql01
		#Creamos los puntos de montaje
		mkdir -p /bd/mylog
		#Añadimos los nuevos puntos de montaje al archivo fstab
		echo "/dev/logs_mysql/lv_logs_mysql01    /bd/mylog       xfs    defaults        1 2" >> /etc/fstab
		#Montamos los nuevos volúmenes
		mount -a
}

create_disk_mysql_bakcup(){
		#creamos la partición en el disco
        (echo o; echo n; echo p; echo 1; echo ; echo; echo w) | fdisk /dev/sdd
		#creamos el volumen en el primer disco
        pvcreate /dev/sdd1
        #creamos el volumegroup
        vgcreate backup_mysql /dev/sdd1
        #Asignamos el tamaño total
        lvcreate -l100%FREE -n lv_bakcup_mysql01 backup_mysql
		#Damos formato al disco	
		mkfs.xfs /dev/backup_mysql/lv_bakcup_mysql01
		#Creamos los puntos de montaje
		mkdir -p /bd/mybackup
		#Añadimos los nuevos puntos de montaje al archivo fstab
		echo "/dev/backup_mysql/lv_bakcup_mysql01    /bd/mybackup       xfs    defaults        1 2" >> /etc/fstab
		#Montamos los nuevos volúmenes
		mount -a
}

case $1 in
	"apache")
		echo "apache"
		create_disk_apache_data
		create_disk_logs_apache
		lsblk -f
		df -h
		exit 0
	;;
	"tomcat")
		create_disk_logs_tomcat
		create_disk_tomcat_data
		lsblk -f
		df -h
		exit 0
	;;
	"mysql")
		create_disk_mysql_data
		create_disk_mysql_logs
		create_disk_mysql_bakcup
		lsblk -f
		df -h
		exit 0
	;;
	*)
		echo "Opción no válida"
		exit 1
	;;
	esac
