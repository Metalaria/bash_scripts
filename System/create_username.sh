#!/bin/sh

#Autor: Gonzalo Mejías Moreno

# Sencillo script que gestiona los usuarios en un sistema linux
# 
#   -c: Crea un usuario (standard UID)
#   -m: Modifica la password de un usuario.
#   -b: Borra un usuario
#   -o: Override: Si el usuario existe, le cambia la password (Crear)
#                 Si el usuario no existe al modificarlo, lo crea (Modificar)
#   -a: Borra el home del usuario y sus cuentas de correo
#   -u: Usuario
#   -p: Password
#

function GetAyuda {
	echo "Parametros incorrectos. Uso:"
	echo ""
	echo "   $0 (-c|-m|-b) [-o] -u USUARIO [-p PASSWORD]"
	echo ""
	echo " -c: Crea un usuario (standard UID)"
	echo " -m: Modifica la password de un usuario."
	echo " -b: Borra un usuario."
	echo " -o: Override: Si el usuario existe, le cambia la password (Crear)"
	echo "               Si el usuario no existe al modificarlo, lo crea (Modificar)"
	echo " -a: Borra el home del usuario y sus cuentas de correo"
	echo " -u: Usuario"
	echo " -p: Password"
	echo " "
}

OVERRIDE=0
ACCION=0
DELETEALL=0

while getopts "bcmoau:p:" opcion; do
	case $opcion in
		b) ACCION=1
		;;
		c) ACCION=2
		;;
		m) ACCION=3
		;;
		o) OVERRIDE=1
		;;
		a) DELETEALL=1
		;;
		u) USUARIO="$OPTARG"
		;;
		p) PASSWORD="$OPTARG"
		;;
		?) GetAyuda
		   echo "Fin del script"
		   exit 100
		;;
	esac
done

PASSWD=/usr/bin/passwd
USERADD=/usr/sbin/useradd
USERDEL=/usr/sbin/userdel

function ResetPassword {
  # Parametro 1: Usuario
  # Parametro 2: Password
	echo "${2}" | $PASSWD --stdin -f "${1}"
	RETVAL=$?
	return $RETVAL
}

function CreateUser {
  # Parametro 1: Usuario
  # Parametro 2: Password
	$USERADD -m "${1}"
	RETVAL=$?
	if [ $RETVAL -ne 0 ]; then
		return $RETVAL
	fi
	ResetPassword "${1}" "${2}"
	RETVAL=$?
	if [ $RETVAL -ne 0 ]; then
		return $RETVAL
	fi
	return 0
}

function DeleteUser {
	# Parametro 1: Usuario
	# Parametro 2: Delete all (1 si -- 2 no)
	if [ $2 -eq 1 ]; then
		$USERDEL -rf "${1}"
		RETVAL=$?
		return $RETVAL
	else
		$USERDEL -f "${1}"
		RETVAL=$?
		return $RETVAL
	fi
}

if [ $ACCION -eq 0 ]; then
	echo "No se ha especificado una accion."
	echo ""
	GetAyuda
	exit 1
fi

if [ $ACCION -eq 2 ]; then
	# Crear usuario. Comprueba si existe
	if [ `cat /etc/passwd | grep -c "^${USUARIO}"` -eq 1 ]; then
		# Existe. Si hay override resetea la password
		if [ $OVERRIDE -eq 1 ]; then
			ResetPassword "${USUARIO}" "${PASSWORD}"
			RETVAL=$?
			if [ $RETVAL -eq 0 ]; then
				echo "El usuario existia, por lo que se reseteo la password"
				exit 0
			else
				echo "Ha habido un problema al resetear la password"
				exit 10
			fi
		else
			echo "El usuario ya existe"
			exit 20
		fi
	else
		# Creamos el usuario
		CreateUser "${USUARIO}" "${PASSWORD}"
		RETVAL=$?
		if [ $RETVAL -eq 0 ]; then
			echo "Usuario ${USUARIO} creado correctamente"
			exit 0
		else
			echo "Ha habido un problema al crear el usuario ${USUARIO}"
			exit 30
		fi
	fi
elif [ $ACCION -eq 3 ]; then
	# Modifica la contrasena
	if [ `cat /etc/passwd | grep -c "^${USUARIO}"` -eq 0 ]; then
		# No existe. Si hay override lo crea.
		if [ $OVERRIDE -eq 1 ]; then
			CreateUser "${USUARIO}" "${PASSWORD}"
			RETVAL=$?
			if [ $RETVAL -eq 0 ]; then
				echo "El usuario no existia, asi que se ha creado."
				exit 0
			else
				echo "Ha habido un problema al crear el usuario."
				exit 30
			fi
		fi
	else
		#Usuario existe
		ResetPassword "${USUARIO}" "${PASSWORD}"
		RETVAL=$?
		if [ $RETVAL -eq 0 ]; then
			echo "Se ha reseteado la password de ${USUARIO} con exito"
			exit 0
		else
			echo "Ha habido un problema al resetear la password"
			exit 10
		fi
	fi
elif [ $ACCION -eq 1 ]; then
	if [ `cat /etc/passwd | grep -c "^${USUARIO}"` -eq 0 ]; then
		echo "El usuario no existe, por lo que no se puede eliminar"
		exit 50
	else
		# Borra el usuario
		DeleteUser "${USUARIO}" "${DELETEALL}"
		if [ $RETVAL -eq 0 ]; then
			echo "Se ha eliminado ${USUARIO} con exito"
			exit 0
		else
			echo "Ha habido un problema al borrar el usuario"
			exit 60
		fi
	fi
else
	echo "Se ha producido un error desconocido"
	exit 200
fi

echo "Fin prematuro del script"
exit 201
