#!/bin/bash
# Find IP addresses in endlesssh tarpit and add to hosts.deny file - endless ssh tarpit container lscr.io/linuxserver/endlessh
#
# Version 1.1
# Author: Meir Lazar

tarpitlog='${HOME}/dockerfiles/endlessh/appdata/logs/endlessh/current' # location of log using endless tarpit
myip=$(curl ifconfig.me) # ignore my external ip

# get failed attempt ipv4 addresses, ignoring 10.x.x.x, 192.168.x.x, 127.0.0.1, and my external ip addresses. remove duplicates.
failed=$(grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' ${tarpitlog} | grep -vE "127.0.0.1|10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|192.168\.[0-9]{1,3}\.[0-9]{1,3}|${myip}" | sort | uniq)

# check if /etc/hosts.deny already has that ip listed, and if not, add it to not allow any traffic from that IP source. 
while IFS= read -r x; do
        if ! grep "${x}" <"/etc/hosts.deny"; then echo "ALL : ${x}" | sudo tee -a /etc/hosts.deny ; fi
done <<< ${failed}
