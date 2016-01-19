#!/bin/sh
set -euf -o pipefail

apt-get remove --purge 'linux-image-[0-9].*' linux-image-$(uname -r)+
apt-get remove --purge 'linux-headers-[0-9].*' linux-headers-$(uname -r)+
update-grub2

exit 0
