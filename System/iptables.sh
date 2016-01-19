#!/bin/bash

#Autor: Gonzalo Mejías Moreno

#Configura iptables service para que se inicie en cada arranqye de la máquina
chkconfig --level 235 iptables on

# Flush todas las reeglas actuales
iptables -F

iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -m state --state NEW,RELATED,ESTABLISHED -j ACCEPT

# Permite: ssh, smtp, http, https, pings, local traffic
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -p tcp --dport 25 -j ACCEPT
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT
iptables -A INPUT -p icmp -j ACCEPT
iptables -A INPUT -s 127.0.0.1 -j ACCEPT


# REJECT: Todo lo que no esté explicitamente definido
iptables -A INPUT -j REJECT
iptables -A FORWARD -j REJECT

/usr/libexec/iptables.init save 

exit 0
