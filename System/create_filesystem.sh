#!/bin/bash
#Version 5
#Fecha: 19/01/2016
#Autor: Gonzalo Mejías Moreno

#Este script sirve para reconocer y dar formato en caliente a los discos duros sin uso de una máquina virtual en WMware.
#Busca en todos los discos de la máquina y filtra el de sistema (el sda normalmente) y aquellos discos que ya tengan una partición.
#Para ello pregunta si va a usar LVM o no y en función de ello realiza una acción y otra.
#Si se selecciona partición pregunta a su vez si se quiere crean un volumegroup con más de un disco duro
#El script formatea los discos en xfs, pero se podrían utilizar otros formatos cambiando la línea del mkfs
#Todo lo que realiza el script lo escribe en un archivo de log llamado create_filesystem.log

#Reescaneado del bus isci en busca de nuevos discos duros
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
                        echo "Disco sobre el que se va actuar: " ${disks[$j-1]}
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
                        sleep 0.5
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
				
				echo "Crear un volumegroup con más de un disco? s/n"
				read resp2
				case $resp2 in
				"s")
					disks_parted_for_volume=`lsblk -nfs | grep "^sd" | grep -v "^sda" | cut -d " " -f1,2,3,4 | sed '/^$/d' | tr -d ' '`
					echo "Discos disponibles: "
					echo  "${disks_parted_for_volume[@]}"
					echo "Nombre del volumegroup:"
					read name_volume_group
					name_volume_group_no_spaces=`echo "$name_volume_group" | tr -d ' '`
					echo "$name_volume_group_no_spaces"
					echo "Discos que van a formar parte del volumegroup?"
					read disks_volume_group
#					while read disks_volume_group
#					do
						#echo "${disks_parted_for_volume[@]}" 
						if [ "$?" = "1" ]; then
							echo "Disco duro no válido, las posibilidades son: " "${disks[@]}"
							echo "Vuelve a introducirlos"
						else
							#creamos un array con los discos duros que hemos introducido por teclado
							declare -a array_of_disk=( $disks_volume_group )
#							creamos un array vacio
							declare -a empty_array_of_disk=( )
#							En este bucle concatenamos "/dev/" a los discos introducidos por teclado y los guarda en el array vacío de antes
							for k in $(seq 1 ${#array_of_disk[@]}); do	
								insert="/dev/"${array_of_disk[$k-1]}
								empty_array_of_disk+=($insert)
								echo ${empty_array_of_disk[$k-1]}
							done
#							Convertimos los discos en volúmenes
							pvcreate /${empty_array_of_disk[@]} >> create_filesystem.log
#							Creamos el volumegroup
							vgcreate $name_volume_group_no_spaces ${empty_array_of_disk[@]} >> create_filesystem.log
							echo "Nombre del volumen?"
							read name_of_volume_disk
							name_of_volume_disk_no_spaces=`echo "$name_of_volume_disk" | tr -d ' '`
#							Creamos el volumen con todos los discos con el 100% del espacio
							lvcreate -l100%FREE -n $name_of_volume_disk_no_spaces $name_volume_group_no_spaces >> create_filesystem.log
#							Damos formato al volumen
							mkfs.xfs /dev/$name_volume_group_no_spaces/$name_of_volume_disk_no_spaces >> create_filesystem.log
#							test de montaje
							mkdir -p /test/test
#							Añadimos el punto de montaje en el fstab
							echo "/dev/$name_volume_group_no_spaces/$name_of_volume_disk_no_spaces /test/test    xfs     defaults        1 2" >> /etc/fstab
#							Montamos el volumen
							mount -a
							df -h
							exit 0
        					fi
						#read disks_volume_group
#					done
				#done
				;;
				"n")
					exit 1
				;;
				*)
					echo "Opción no válida"
					exit 1
				;;
			esac

                exit 0
                ;;
        *)
                echo "Opción no válida"
                exit 1
        ;;

esac

exit 0
