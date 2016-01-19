#!/bin/bash

# Script la siguiente info de la máquina
#	-> uname -a
#	-> interrupts
#	-> devices
#	-> cpuinfo
#	-> modules
#	-> meminfo
#	-> kernel* rpms
#	-> directorios en /usr/src
#	-> directorios en /lib/modules

LOG=sysinfo.log

>$LOG
uname -a >> $LOG

echo "****{ Interrupts }****" >> $LOG
cat /proc/interrupts >> $LOG

echo " " >> $LOG
echo "****{ Devices }****" >> $LOG
cat /proc/devices >> $LOG

echo " " >> $LOG
echo "****{ CPU Info }****" >> $LOG
cat /proc/cpuinfo >> $LOG

echo " " >> $LOG
echo "****{ Module Info }****" >> $LOG
cat /proc/modules >> $LOG

echo " " >> $LOG
echo "****{ Module Info }****" >> $LOG
cat /proc/meminfo >> $LOG

echo " " >> $LOG
echo "****{ Kernel Pkg }****" >> $LOG
rpm -qa | grep kernel >> $LOG

echo " " >> $LOG
echo "****{ /usr/src }***" >> $LOG
ls -l /usr/src >> $LOG

echo " " >> $LOG
echo "****{ /lib/modules }****" >> $LOG
ls -l /lib/modules/* >> $LOG

egrep "pci_read|pci_write" /proc/ksyms >> $LOG

exit 0
