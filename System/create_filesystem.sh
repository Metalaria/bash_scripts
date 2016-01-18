#!/bin/bash
#Version 4
#Fecha: 18/01/2016
#Autor: Gonzalo Mejías Moreno

#Este script sirve para reconocer y dar formato en caliente a los discos duros sin uso de una máquina.
#Busca en todos los discos de la máquina y filtra el de sistema, el sda normalmente y aquellos discos que ya tengan una partición.
#Para ello pregunta si va a usar LVM o no y en función de ello realiza una acción y otra.
#El script formatea los discos en xfs, pero se podrían utilizar otros formatos cambiando la línea del mkfs
#Todo lo que realiza el script lo escribe en un archivo de log llamado create_filesystem.log

# Reescaneo el bus isci en busca de nuevos discos duros
for i in `ls -1 /sys/class/scsi_host/ | awk -F 'host' '{ print $2 }'`; do
        echo "- - -" > /sys/class/scsi_host/host${i}/scan
        ls -l /sys/class/scsi_host/host${i}
done

#creación de un array con los discos que no están en uso en la máquina
disks=(`lsblk -nfs | grep "^sd" | grep -v "^sda" | cut -d " " -f1,2,3,4 | sed '/^$/d' | grep -v '[0-9]' | tr -d ' '`)

echo "Todos los discos" `lsblk -nfs | grep "^sd" | grep -v "^sda" | cut -d " " -f1,2,3,4 | sed '/^$/d' |  grep -v '[0-9]'`

echo "LVM o no? s/n"
read resp

case $resp in
        "s")
#               realiza la misma acción por cada uno de los discos sin uso de la máquina
                for j in $(lsblk -nfs | grep "^sd" | grep -v "^sda" | cut -d " " -f1,2,3,4 | sed '/^$/d' | grep -v '[0-9]' | tr -d ' ' | awk -F '^sd*' '{ print NR }'); do
#                       imprime el disco sobre el que se va actuar
                        echo ${disks[$j-1]}
#                       creación de una partición en el disco duro
                        (echo o; echo n; echo p; echo 1; echo ; echo; echo w) | fdisk /dev/${disks[$j-1]} >> create_filesystem.log
#                       creación del volumen en el disco actual
                        pvcreate /dev/${disks[$j-1]}1 >> create_filesystem.log
#                       creación del volume group
                        vgcreate vg0${j} /dev/${disks[$j-1]}1 >> create_filesystem.log
#                       creación del volumen utilizando todo el tamaño del disco
                        lvcreate -l100%FREE -n lv_01 vg0${j} >> create_filesystem.log
#                       formateo del volumen en xfs
                        mkfs.xfs /dev/vg0${j}/lv_01 >> create_filesystem.log
                        echo ""
                        sleep 1
                done

                lsblk -f

                exit 0
                ;;
        "n")
#               realiza la misma acción por cada uno de los discos sin uso de la máquina
                for j in $(lsblk -nfs | grep "^sd" | grep -v "^sda" | cut -d " " -f1,2,3,4 | sed '/^$/d' | grep -v '[0-9]' | tr -d ' ' | awk -F '^sd*' '{ print NR }'); do
#                       muestra el disco sobre el que se va a actuar
                        echo ${disks[$j-1]}
#                       creación de  una partición en el disco duro
                        (echo o; echo n; echo p; echo 1; echo ; echo; echo w) | fdisk /dev/${disks[$j-1]} >> create_filesystem.log
#                       formateo de la partición en xfs
                        mkfs.xfs /dev/${disks[$j-1]}1 >> create_filesystem.log
                        sleep 1
                done

                lsblk -f

                exit 0
                ;;
        *)
                echo "Opción no válida"
                exit 1
        ;;

esac
