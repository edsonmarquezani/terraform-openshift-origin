#!/bin/bash

iptables -I OS_FIREWALL_ALLOW -p tcp -m state --state NEW -m tcp --dport 80:81 -j ACCEPT
iptables -I OS_FIREWALL_ALLOW -p tcp -m state --state NEW -m tcp --dport 443:444 -j ACCEPT
sed -i 's/--dport 80/--dport 80:81/g' /etc/sysconfig/iptables
sed -i 's/--dport 443/--dport 443:444/g' /etc/sysconfig/iptables
