#!/bin/bash

# update_iptables_docker.sh
# This is a configuration for iptables used with docker 
# ©2022 Clément Levoux

IPT="/sbin/iptables"
#IPTs4="/sbin/iptables-save"
#IPTs6="/sbin/ip6tables-save"
REPOSITORY_SERVER="download.docker.com ftp.us.debian.org ftp.fr.debian.org security.debian.org deb.debian.org "
SSH_PORT=$1
DNS=${@:2}

echo "IPTABLES - RESET F"
$IPT -F
echo "IPTABLES - RESET X"
$IPT -X
echo "IPTABLES - RESET NAT F"
$IPT -t nat -F
echo "IPTABLES - RESET NAT X"
$IPT -t nat -X
echo "IPTABLES - RESET MANGLE F"
$IPT -t mangle -F
echo "IPTABLES - RESET MANGLE X"
$IPT -t mangle -X


echo "IPTABLES - SSH ($SSH_PORT) ACCEPT"
$IPT -t filter -A INPUT -p TCP --dport $SSH_PORT -j ACCEPT
$IPT -t filter -A OUTPUT -p TCP --sport $SSH_PORT -j ACCEPT

echo "IPTABLES - CONFIG DNS"
for ipDNS in $DNS
do
	echo "Allowing DNS lookups (tcp, udp port 53) to server '$ipDNS'"
	$IPT -A OUTPUT -p udp -d $ipDNS --dport 53 -m state --state NEW,ESTABLISHED -j ACCEPT
	$IPT -A INPUT  -p udp -s $ipDNS --sport 53 -m state --state ESTABLISHED     -j ACCEPT
	$IPT -A OUTPUT -p tcp -d $ipDNS --dport 53 -m state --state NEW,ESTABLISHED -j ACCEPT
	$IPT -A INPUT  -p tcp -s $ipDNS --sport 53 -m state --state ESTABLISHED     -j ACCEPT
done

echo "IPTABLES - CONFIG REPOSITORY CONFIGURATION"
for ipPack in $REPOSITORY_SERVER
do
	echo "Allow connection to $ipPack on port 21"
	$IPT -A OUTPUT -p tcp -d "$ipPack" --dport 21  -m state --state NEW,ESTABLISHED -j ACCEPT
	$IPT -A INPUT  -p tcp -s "$ipPack" --sport 21  -m state --state ESTABLISHED     -j ACCEPT
done

echo "IPTABLES - CONFIG WEB"
$IPT -t filter -A OUTPUT -p tcp -m multiport --dports 80,443,8000 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
$IPT -t filter -A INPUT -p tcp -m multiport --sports 80,443,8000 -m conntrack --ctstate ESTABLISHED -j ACCEPT

echo "IPTABLES - CONFIG DOCKER"
$IPT -t filter -A OUTPUT -p tcp -m multiport --dports 2376,2377,7946 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
$IPT -t filter -A INPUT -p tcp -m multiport --sports 2376,2377,7946 -m conntrack --ctstate ESTABLISHED -j ACCEPT
$IPT -t filter -A OUTPUT -p udp -m multiport --dports 7946,4789 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
$IPT -t filter -A INPUT -p udp -m multiport --sports 7946,4789 -m conntrack --ctstate ESTABLISHED -j ACCEPT

#Allow trafic on internal network
echo "IPTABLES - CONFIG IO"
$IPT -t filter -A INPUT -i lo -j ACCEPT
$IPT -t filter -A OUTPUT -o lo -j ACCEPT

echo "IPTABLES - CONFIG PING"
$IPT -A OUTPUT -o eth0 -p icmp -m conntrack --ctstate NEW,ESTABLISHED,RELATED -j ACCEPT
$IPT -A INPUT -i eth0 -p icmp -m conntrack --ctstate NEW,ESTABLISHED,RELATED -j ACCEPT


echo "IPTABLES - DROP INPUT"
$IPT -P INPUT DROP
echo "IPTABLES - DROP FORWARD"
$IPT -P FORWARD DROP
echo "IPTABLES - DROP OUTPUT"
$IPT -P OUTPUT DROP

# Log before dropping
#$IPT -N LOGGING
#$IPT -A INPUT -j LOGGING
#$IPT -A LOGGING -j LOG  -m limit --limit 12/min --log-level 4 --log-prefix 'IP INPUT drop: '
#$IPT -A LOGGING -j DROP

#$IPT -N LOGGING
#$IPT -A OUTPUT -j LOGGING
#$IPT -A LOGGING -j LOG  -m limit --limit 12/min --log-level 4 --log-prefix 'IP OUTPUT drop: '
#$IPT -A LOGGING -j DROP

#sudo apt install iptables-persistent -y

#$IPT4 > /etc/iptables/rules.v4
#$IPTs6 > /etc/iptables/rules.v6

echo "IPTABLES - LIST"
$IPT -L

#sudo iptables-translate -A LOGGING -j LOG  -m limit --limit 12/min --log-level 4 --log-prefix 'IP INPUT drop: '
