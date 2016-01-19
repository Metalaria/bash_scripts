#!/bin/bash
#Autor: Gonzalo Mejías Moreno
olduser=$1
newuser=$2
set -x
# get user account context
id $olduser
grep ^$olduser: /etc/passwd
grep ^$olduser: /etc/group

# get home folder permissions
ls -ld /home/$olduser/

# get process owned by $olduser user/group
ps aux | grep $olduser
ps -u $olduser

# proceed only if processes are not owned by $olduser

# begin changes
# change $olduser account name
usermod -l $newuser $olduser
id $olduser
ls -ld /home/$olduser

# change $olduser primary groupname
id $olduser
groupmod -n $newuser $olduser
id $olduser
ls -ld /home/$olduser

# move $olduser home folder
usermod -d /home/$newuser -m $newuser
id $newuser
ls -ld /home/$newuser

# change $olduser UID
# id $olduser
# usermod -u nnn $olduser
# id $olduser
