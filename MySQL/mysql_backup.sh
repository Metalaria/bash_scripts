#!/bin/sh
#
# Funciones:
#   Hace un backup de las bases de datos en un archivo comprimido (pigz o gzip)
# Requisitos:
#   MySQL client/mysqldump
#   Usuario con permisos
# USO: cd /var/backups/db && backup_mysql_dbs.sh


TODAY=`date +%Y-%m-%d`
COMP_TOOL=gzip
which pigz >/dev/null 2>&1 && COMP_TOOL=pigz

logger "Copiando todas las bbdd ..."

# comprobamos el servidor maestro:
mysql -e "show global variables like 'log_bin'"|grep ON
if [ "$?" -eq "0" ]; then
  FLAGS="--master-data"
else
  FLAGS=""
fi

DBS=`mysql --skip-column-names -e "show databases"`

for DB in $DBS; do
  if [ ! -d $DB ]; then
    mkdir $DB
  fi
  DUMPFILE="${DB}_${TODAY}.sql.gz"
  echo -n "${DB} (`date '+%H:%M:%S'`) - "
  mysqldump $FLAGS --triggers --routines "${DB}" | $COMP_TOOL > ${DB}/${DUMPFILE}
  echo "done (`date '+%H:%M:%S'`)"
done

exit 0
