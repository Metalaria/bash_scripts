#!/bin/bash
set -euf -o pipefail -o xtrace

Elimina los paquetes dañados en debian/ubuntu usando apt-get y dpkg.

apt-get remove $1
rm /var/lib/dpkg/info/$1
dpkg --remove --force-remove-reinstreq $1

exit 0
