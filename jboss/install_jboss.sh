#!/bin/bash

# Copyright Rimuhosting.com

# Modificado por Gonzalo Mejías Moreno

DEFAULTINSTALLTARGET="/servicios/jboss"
INSTALLTARGET=
INITSCRIPT="/etc/init.d/jboss"
JBOSSURL="http://download.jboss.org/jbossas/7.1/jboss-as-7.1.1.Final/jboss-as-7.1.1.Final.tar.gz"
MYSQLCONNECTORURL="https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.38.tar.gz"
# Valores por defecto
ERRORMSG=
MVDIRSTAMP="old.$(date +%s)"
MVDIRNAME=
NOPROMPT=
NOJAVA="n"
RUNONSTARTUP="n"
MYSQLCONNECTOR="n"

# Imprime lo que hace el script
function uso {
  echo " Uso: $0 [--noprompt]
      [--installtarget <carpeta>] [--skip-java]
      [--mysqlconnector]
      [--runonstartup]
  Notas opcionales:
  --noprompt      Totalmente automático, sin interacción
  --installtarget Si quieres cambiar el directorio de instación (por defecto $DEFAULTINSTALLTARGET)
"
}

# Coge los parámetros de entrada 
function parsecommandline {
  while [ -n "$1" ]; do
    PARAM=$1
    case "$1" in
    --noprompt)
      NOPROMPT=n
      ;;
    --installtarget)
      shift
      if [[ -e "$1" && ! -d "$1" ]]; then
        ERRORMSG="El objetivo $1 eya existe pero no es un directorio"
        return 1
      fi
      if [[ $(echo $1 | grep ^/ ) == "0" ]]; then
        ERRORMSG="--installtarget debe ser una ruta absoluta"
        return 1
      fi
      INSTALLTARGET="$1"
      ;;
    --runonstartup)
      RUNONSTARTUP="y"
      ;;
    --skip-java)
      NOJAVA="y"
      ;;
    --mysqlconnector)
      MYSQLCONNECTOR="y"
      ;;
    -h|help|-help|--help|?|-?|--?)
      uso
      exit 1;
      ;;
    *)
      ERRORMSG="Parámetro no válido '$PARAM'"
      return 1;
      ;;
    esac
    shift
  done

  INSTALLTARGET=${INSTALLTARGET:-$DEFAULTINSTALLTARGET}

  # detecta el sistema operativo y su versión
  
  if [ -e /etc/redhat-release ]; then
      DISTRO=( `grep release /etc/redhat-release | awk '{print $1}'` )
      RELEASE=( `grep release /etc/redhat-release | awk '{print $4}' | cut -d. -f1` )
elif [ -e /etc/susehelp.d/ ]; then
      DISTRO=`lsb_release -is | awk '{print $1}'`
      RELEASE=`lsb_release -rs`
  elif [ -e /etc/debian_version ]; then
      if ( ! which lsb_release >/dev/null ); then
          echo "  ...instalando 'lsb_release' command"
          apt-get -y -qq install lsb-release  >> /dev/null 2>&1
          if [[ $? -ne 0 ]]; then echo "Error: installing lsb_release package failed"; exit 1; fi
      fi
  # elif [ -e /etc/susehelp.d/ ]; then
   #     DISTRO=`lsb_release -is | awk '{print $1}'`
   #     RELEASE=`lsb_release -rs`
   #fi
      DISTRO=$( lsb_release -is )
      RELEASE=$( lsb_release -rs | cut -d. -f1)
  else
      echo "No se reconoce la distro , es posible que algunas funciones no funcionen" "$DISTRO"
  fi
  [[ -z "$DISTRO" ]] && echo "! Warning: No se ha detectado la distro"
  [[ -z "$RELEASE" ]] && echo "! Warning: No se ha identificado la versión"
  
  return 0

}

# Comprueba que los componentes necesarios para el funcionamiento de jboss están instalados
function installreqs {
  echo "* Comprobando los requisitos de instalación"
  if [[ $(id -u) != "0" ]] ; then
    ERRORMSG="Es necesario ejecutarlo como root (sudo $0 $* ) "
    return 1
  fi

  echo "  ...Comprobando si hay algún jboss ya instalado"
  if [[ -d $INSTALLTARGET && $(ls -1 "$INSTALLTARGET" | wc -l) != 0 ]]; then
    
    if [[ -z $NOPROMPT ]]; then
      echo " La carpeta $INSTALLTARGET ya existe, Ctrl-C para salir o Enter para continuar y hacer un backup de esos archivos... "
      read -s
    else
      ERRORMSG="$INSTALLTARGET no está vacío, --noprompt, la ejecución del script se detiene"
      return 1
    fi
  fi

  [[ -e /etc/profile.d/java.sh ]] && source /etc/profile.d/java.sh
  if [[ ! $(which java 2>/dev/null) ]]; then
    if [ "$NOJAVA" = "y" ]; then
      ERRORMSG="No se ha encontrado java"
      exit 1
    fi
  fi

}

# Actually do the jboss package install
function installjboss {
  echo "* Instalando jboss"

  # Mueve los scripts de inicio antiguos a un directorio de backup
  MVDIRNAME="$INSTALLTARGET.$MVDIRSTAMP"
  jbossscripts=`find /etc/init.d/ | xargs grep -c $INSTALLTARGET | grep -v ":0$" | cut -d: -f1`
  if [ ! -z "$jbossscripts" ]; then
    for i in $jbossscripts; do
      echo "  ...instentando parar la instancia actual de jboss controlada por $i"
      $i stop  >> /dev/null 2>&1
      sleep 1
      if [[ $($i status | grep -c 'PIDs') > 0 ]]; then
        ERRORMSG="jboss no se ha detenido correctamente"
        return 1
      fi
    done
      if [ "$(ps aux | grep -c "^jboss")" -ne "0" ]; then
	ERRORMSG="usuario jboss todavía tiene un proceso corriendo"
	return 1
      fi
    for i in $jbossscripts; do
      echo "  ...init script $i movido a $(dirname $INSTALLTARGET)/$(basename $i).$MVDIRSTAMP.init"
      mv $i "$(dirname $INSTALLTARGET)/$(basename $i).$MVDIRSTAMP.init"
    done
  fi

  if [ -e $INSTALLTARGET ]; then
    echo "  ...encontrado $INSTALLTARGET, haciendo un backup del directorio a $MVDIRNAME"
    mv "$INSTALLTARGET" "$MVDIRNAME"
  fi

  #Nuevo script de inicio	
  echo <<INITSCRIPTEOF >$INITSCRIPT '
#!/bin/sh
#
# JBoss standalone control script
#
# chkconfig: - 80 20
# description: JBoss AS Standalone
# processname: standalone
# pidfile: /var/run/jboss-as/jboss-as-standalone.pid
# config: /etc/jboss-as/jboss-as.conf

# Source function library.
#. /etc/init.d/functions
. /lib/lsb/init-functions

# Load Java configuration.
[ -r /etc/java/java.conf ] && . /etc/java/java.conf
export JAVA_HOME

# Load JBoss AS init.d configuration.
if [ -z "$JBOSS_CONF" ]; then
  JBOSS_CONF="/servicios/jboss/bin/init.d/jboss-as.conf"
fi

[ -r "$JBOSS_CONF" ] && . "${JBOSS_CONF}"

# Set defaults.

if [ -z "$JBOSS_HOME" ]; then
  JBOSS_HOME=/servicios/jboss
fi
export JBOSS_HOME

if [ -z "$JBOSS_PIDFILE" ]; then
  JBOSS_PIDFILE=/var/run/jboss-as/jboss-as-standalone.pid
fi
export JBOSS_PIDFILE

if [ -z "$JBOSS_CONSOLE_LOG" ]; then
  JBOSS_CONSOLE_LOG=/logs/jboss/console.log
fi

if [ -z "$STARTUP_WAIT" ]; then
  STARTUP_WAIT=30
fi

if [ -z "$SHUTDOWN_WAIT" ]; then
  SHUTDOWN_WAIT=30
fi

if [ -z "$JBOSS_CONFIG" ]; then
  JBOSS_CONFIG=standalone.xml
fi

JBOSS_SCRIPT=/servicios/jboss/bin/standalone.sh

prog='jboss-as'

CMD_PREFIX=''

if [ ! -z "$JBOSS_USER" ]; then
  if [ -x /etc/rc.d/init.d/functions ]; then
    CMD_PREFIX="daemon --user $JBOSS_USER"
  else
    CMD_PREFIX="su - $JBOSS_USER -c"
  fi
fi

start() {
  echo -n "Starting $prog: "
  if [ -f $JBOSS_PIDFILE ]; then
    read ppid < $JBOSS_PIDFILE
    if [ `ps --pid $ppid 2> /dev/null | grep -c $ppid 2> /dev/null` -eq '1' ]; then
      echo -n "$prog is already running"
      #failure
      echo
      return 1 
    else
      rm -f $JBOSS_PIDFILE
    fi
  fi
  mkdir -p $(dirname $JBOSS_CONSOLE_LOG)
  cat /dev/null > $JBOSS_CONSOLE_LOG

  mkdir -p $(dirname $JBOSS_PIDFILE)
  chown $JBOSS_USER $(dirname $JBOSS_PIDFILE) || true
  #$CMD_PREFIX JBOSS_PIDFILE=$JBOSS_PIDFILE $JBOSS_SCRIPT 2>&1 > $JBOSS_CONSOLE_LOG &
  #$CMD_PREFIX JBOSS_PIDFILE=$JBOSS_PIDFILE $JBOSS_SCRIPT &

  if [ ! -z "$JBOSS_USER" ]; then
    if [ -x /etc/rc.d/init.d/functions ]; then
      daemon --user $JBOSS_USER LAUNCH_JBOSS_IN_BACKGROUND=1 JBOSS_PIDFILE=$JBOSS_PIDFILE $JBOSS_SCRIPT -c $JBOSS_CONFIG 2>&1 > $JBOSS_CONSOLE_LOG &
    else
      su $JBOSS_USER -c "LAUNCH_JBOSS_IN_BACKGROUND=1 JBOSS_PIDFILE=$JBOSS_PIDFILE $JBOSS_SCRIPT 2>&1 > $JBOSS_CONSOLE_LOG &"
    fi
  fi

  count=0
  launched=false

  until [ $count -gt $STARTUP_WAIT ]
  do
    grep 'JBoss AS.*started in' $JBOSS_CONSOLE_LOG > /dev/null 
    if [ $? -eq 0 ] ; then
      launched=true
      break
    fi 
    sleep 1
    set count=$count+1;
  done
  
  success
  echo
  return 0
}

stop() {
  echo -n $"Stopping $prog: "
  count=0;

  if [ -f $JBOSS_PIDFILE ]; then
    read kpid < $JBOSS_PIDFILE
    set kwait=$SHUTDOWN_WAIT

    # Try issuing SIGTERM

    kill -15 $kpid
    until [ `ps --pid $kpid 2> /dev/null | grep -c $kpid 2> /dev/null` -eq '0' ] || [ $count -gt $kwait ]
    do
      sleep 1
      set count=$count+1;
    done

    if [ "$count" -gt "$kwait" ]; then
      kill -9 $kpid
    fi
  fi
  rm -f $JBOSS_PIDFILE
  echo "success"
  echo ""
}

status() {
  if [ -f $JBOSS_PIDFILE ]; then
    read ppid < $JBOSS_PIDFILE
    if [ `ps --pid $ppid 2> /dev/null | grep -c $ppid 2> /dev/null` -eq '1' ]; then
      echo "$prog is running (pid $ppid)"
      return 0
    else
      echo "$prog dead but pid file exists"
      return 1
    fi
  fi
  echo "$prog is not running"
  return 3
}

case "$1" in
  start)
      start
      ;;
  stop)
      stop
      ;;
  restart)
      $0 stop
      $0 start
      ;;
  status)
      status
      ;;
  *)
      ## If no parameters are given, print which are avaiable.
      echo "Usage: $0 {start|stop|status|restart|reload}"
      exit 1
      ;;
esac
' 
INITSCRIPTEOF

  chmod +x $INITSCRIPT

  # Nos aseguramos que el script de inicio apunta al sitio correcto
  if [[ "$INSTALLTARGET" != "$DEFAULTINSTALLTARGET" ]]; then
    sed -i "s/JBOSS_HOME=$DEFAULTINSTALLTARGET/JBOSS_HOME=$INSTALLTARGET/" $INITSCRIPT
  fi

  echo "  ...Instalando el paquete de jboss en $INSTALLTARGET"
  installtop=$(dirname $INSTALLTARGET)
  cd $installtop
  wget -O - "$JBOSSURL" | tar xz
  if [ $? -ne 0 ]; then ERRORMSG="fallo en la descarga o al descomprimir el paquete"; return 1; fi
#  mv "$installtop"/jboss-as-7* "$INSTALLTARGET"
   rsync -a "$installtop"/jboss-as-7* "$INSTALLTARGET" 
   rm -rf "$installtop"/jboss-as-7* 
   mv "$INSTALLTARGET"/jboss-as-7.1.1.Final/* .."$INSTALLTARGET"
   rm -rf "$INSTALLTARGET"/jboss-as-7.1.1.Final/

 echo

  # creamos el usuario y grupo jboss si no existían antes
  if [[ $(id jboss 2>&1 | grep -c "No such user") -gt "0" ]]; then
    echo "  ...configurando usuario y grupo"
    if [[ $DISTRO == "Debian" || $DISTRO == "Ubuntu" ]]; then
      adduser --system --group jboss --home $INSTALLTARGET >> /dev/null 2>&1
	  usermod -s /bin/bash jboss
    elif [[ $DISTRO == "CentOS" || $DISTRO == "RHEL" || $DISTRO == "Fedora" ]]; then
      groupadd -r -f jboss  >> /dev/null 2>&1
      useradd -r -s /sbin/nologin -d $INSTALLTARGET -g jboss jboss >> /dev/null 2>&1
	  usermod -s /bin/bash jboss
    elif [[$DISTRO == "SUSE"]]; then
	  groupadd -r -f jboss  >> /dev/null 2>&1
      useradd -r -s /sbin/nologin -d $INSTALLTARGET -g jboss jboss >> /dev/null 2>&1 
	  usermod -s /bin/bash jboss
    #fi
    else
      echo "Warning: Distro no reconocida" "$DISTRO"
      groupadd jboss  >> /dev/null 2>&1
      useradd -s /sbin/nologin -d $INSTALLTARGET -g jboss jboss >> /dev/null 2>&1
	  usermod -s /bin/bash jboss
    fi
  fi
  if [[ $(id jboss 2>&1 | grep -c "No such user") -gt 0 ]]; then
    ERRORMSG="fallo al crear el usuario jboss"
    return 1
  fi

  chown -R jboss:jboss $INSTALLTARGET
  chgrp -R -R jboss $INSTALLTARGET

  # configuración de logs
  # configura el servicio para que se inicie en el arranque de la máquina si se quiere

    if [ -z "$NOPROMPT" ] && [ $RUNONSTARTUP = "n"  ]; then
      echo -n "  Hacer que jboss se inicie en el arranque de la máquina? [y/n] "
      read RUNONSTARTUP
      while echo $RUNONSTARTUP | grep -qv '^y$\|^n$' ; do
	echo -n "  Hacer que jboss se inicie en el arranque de la máquina? [y/n] "
        read RUNONSTARTUP
      done
    fi
    
    if [ "$RUNONSTARTUP" = "y" ]; then
      # Hacer que jboss se inicie en el arranque de la máquina
      echo "  ...Haciendo que jboss se inicie en el arranque de la máquina"
    	if [ -e /etc/debian_version ]; then
	  update-rc.d jboss defaults
        else
          chkconfig --add jboss
        fi
    fi
    # Deshabilita el acceso remoto por JMX
    echo "  ...Deshabilitando el acceso remoto por JMX"
    sed -i 's|\(<remoting-connector/>\)|<!-- \1 -->|g' $INSTALLTARGET/standalone/configuration/standalone.xml 
}

function installmysqlconnector {
    echo "  ...Instalando el conector de mysql"
    local MYSQLCONNECTORTARGETDIR="$INSTALLTARGET/modules/com/mysql/main"
    mkdir -p $MYSQLCONNECTORTARGETDIR
    cd $MYSQLCONNECTORTARGETDIR
    wget "$MYSQLCONNECTORURL"
	tar xzf mysql-connector-java*
    echo <<EOFMODULE >$MYSQLCONNECTORTARGETDIR/module.xml '
<?xml version="1.0" encoding="UTF-8"?>
 
<module xmlns="urn:jboss:module:1.0" name="com.mysql">
  <resources>
    <resource-root path="mysql-connector-java-5.1.17-bin.jar"/>
  </resources>
  <dependencies>
    <module name="javax.api"/>
  </dependencies>
</module>
'
EOFMODULE

    sed -i 's/mysql-connector-java.*-bin\.jar/'$(basename $(echo $MYSQLCONNECTORURL | sed 's|^http:/||g'))'/g' $MYSQLCONNECTORTARGETDIR/module.xml

    echo "  ...Añadiendo el conector de mysql al connector driver de jboss"
    sed -i 's|\(<drivers>\)|\1\n\t\t<driver name="mysql" module="com.mysql"/>|g' $INSTALLTARGET/standalone/configuration/standalone.xml

    echo ""
    echo "   Para agregar un origen de datos a una base de datos específica (en mayúsculas lo que necesita TUNNING),"
    echo "   Puedes añadir lo siguiente en los datasources elements en el fichero de configuración:"
    echo "   $INSTALLTARGET/standalone/configuration/standalone.xml"
    echo <<EOFDATASOURCEHELP '
<datasource
        jndi-name="java:/DATABASE" pool-name="my_pool"
        enabled="true" jta="true"
        use-java-context="true" use-ccm="true">
    <connection-url>
        jdbc:mysql://localhost:3306/DATABASE
    </connection-url>
    <driver>
        mysql
    </driver>
    <security>
        <user-name>
            DATABASE_USER
        </user-name>
        <password>
 	    DATABASE_PASSWORD
        </password>
    </security>
    <statement>
        <prepared-statement-cache-size>
            100
        </prepared-statement-cache-size>
        <share-prepared-statements/>
    </statement>
</datasource>
'
EOFDATASOURCEHELP
   
    #Asiganmos los permisos de nuevo por si acaso
    chown -R jboss:jboss $INSTALLTARGET
    return 0
}

parsecommandline $*
if [[ $? -ne 0 ]]; then
  echo
  uso
  echo "! Error después de la instalación: $ERRORMSG"
  echo
  exit 1
fi

installreqs
if [[ $? -ne 0 ]]; then
  echo
  echo "! Error en los requisitos de la máquina: $ERRORMSG"
  echo
  exit 1
fi

installjboss
if [[ $? -ne 0 ]]; then
  echo
  echo "! Error en la instalación: $ERRORMSG"
  echo
  exit 1
fi

if [ -z "$NOPROMPT" ] && [ $MYSQLCONNECTOR = "n" ]; then
  echo -n "  Instalar el conector de mysql? [y/n] "
    read MYSQLCONNECTOR
      while echo $MYSQLCONNECTOR | grep -qv '^y$\|^n$' ; do
	echo -n "  Instalar el conector de mysql? [y/n] "
        read MYSQLCONNECTOR
      done
fi
    
if [ "$MYSQLCONNECTOR" = "y" ]; then
installmysqlconnector
fi
 
change_logs_location(){
    local standalone_xml_logs_search='<file relative-to="jboss.server.log.dir" path="server.log"/>'
    local standalone_xml_logs_replace='<file path="/logs/jboss/server.log"/>'

    local domain_xml_logs_search='<file relative-to="jboss.server.log.dir" path="server.log"/>'
    local domain_xml_logs_replace='<file path="/logs/jboss/server.log"/>'

    local jboss_init_standalone_sh_search="JBOSS_CONSOLE_LOG=/var/log/jboss-as/console.log"
    local jboss_init_standalone_sh_replace="JBOSS_CONSOLE_LOG=/logs/jboss/console.log"

    local bin_appclient_searh='$JBOSS_HOME/appclient/log/boot.log'
    local bin_appclient_replace='/logs/jboss/boot.log'

    local bin_appclient_logs_home_search='$JBOSS_LOG_DIR/boot.log'
    local bin_appclient_logs_home_replace='/logs/jboss/boot.log'

    local jboss_user_search="#JBOSS_USER=jboss-as"
    local jboss_user_replace="JBOSS_USER=jboss"

    local jboss_home_search="JBOSS_HOME=/usr/share/jboss-as"
    local jboss_home_replace="JBOSS_HOME=/servicios/jboss"

    local logs_dir_search='JBOSS_LOG_DIR=`readlink -m ${var#*=}`'
    local logs_dir_replace='JBOSS_LOG_DIR=/logs/jboss'

    local jboss_controller_log_search='$JBOSS_LOG_DIR/process-controller.log'
    local jboss_controller_log_replace='/logs/jboss/process-controller.log'

    local jboss_controller_log_search2='$JBOSS_LOG_DIR/host-controller.log'
    local jboss_controller_log_replace2='/logs/jboss/process-controller.log'

    sed -i "s|$standalone_xml_logs_search|$standalone_xml_logs_replace|g" $INSTALLTARGET/standalone/configuration/standalone.xml
    sed -i "s|$domain_xml_logs_search|$domain_xml_logs_replace|g" $INSTALLTARGET/domain/configuration/domain.xml
    sed -i "s|$jboss_init_standalone_sh_search|$jboss_init_standalone_sh_replace|g" $INSTALLTARGET/bin/init.d/jboss-as-standalone.sh
    sed -i "s|$bin_appclient_searh|$bin_appclient_replace|g" $INSTALLTARGET/bin/appclient.sh
    sed -i "s|$bin_appclient_logs_home_search|$bin_appclient_logs_home_replace|g" $INSTALLTARGET/bin/standalone.sh
    sed -i "s|$bin_appclient_searh|$bin_appclient_replace|g" $INSTALLTARGET/bin/standalone.sh
    sed -i "s|$jboss_controller_log_search|$jboss_controller_log_replace|g" $INSTALLTARGET/bin/domain.sh
    sed -i "s|$jboss_controller_log_search2|$jboss_controller_log_replace2|g" $INSTALLTARGET/bin/domain.sh
    sed -i "s|$jboss_user_search|$jboss_user_replace|g" $INSTALLTARGET/bin/init.d/jboss-as.conf
    sed -i "s|$jboss_home_search|$jboss_home_replace|g" $INSTALLTARGET/bin/init.d/jboss-as.conf
}

change_logs_location

echo -n "* Comprobamos que el servicio está corriendo"
$INITSCRIPT restart >> /dev/null 2>&1
sleep 5

check_status() {
	local timestamp=`date "+%D || %H:%M:%S :"`
	init_process=$(cat /proc/1/comm)	
	if [[ $init_process == "systemd" ]]; then
		local resultado_grep=$(systemctl status apache2.service | grep -c active)
		if [ "$resultado_grep" = "1" ]; then
                echo $timestamp "INFO: El servidor JBOSS ha sido configurado correctamente"
        else
                echo $timestamp "INFO: Ha ocurrido un fallo durate la configuración del servidor"
                systemctl status jboss
        fi
	elif [[ $init_process == "init" ]]; then
		local resultado_grep=$(ps -ef | grep -c jboss)
		if [ "$resultado_grep" = "3" ]; then
                echo $timestamp "INFO: El servidor JBOSS ha sido configurado correctamente"
        else
                echo $timestamp "INFO: Ha ocurrido un fallo durate la configuración del servidor"
        fi
	fi
}

check_status

exit 0
# EOF
