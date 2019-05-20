#!/bin/bash

getopt --test > /dev/null
if [[ $? != 4 ]]; then
	echo "I'm sorry, 'getopt --test' failed in this environment."
	exit 1
fi

#set -o verbose

IPV4_LIST=$(mktemp)
IPV6_LIST=$(mktemp)

zone=
ipv4=
ipv6=
http=
https=

while [ "$1" != "" ]; do
	case $1 in
		--zone )    shift
								zone=$1
								;;
		--ipv4 )    ipv4=1
								;;
		--ipv6 )    ipv6=1
								;;
		--http )    http=1
								;;
		--https )   https=1
								;;
		--help )    usage
								exit
								;;
		* )         usage
								exit 1
	esac
	shift
done

if [ -z "$zone" ]; then
	echo "Zone is not set! Exiting!"
	exit 1
else
	echo "Zone is set to $zone!"
fi
if [ -n "$ipv4" ]; then
	echo "Enabling CloudFlare IPv4 in a zone $zone!"
	curl --silent https://www.cloudflare.com/ips-v4 -o $IPV4_LIST
else
	echo "CloudFlare IPv4 in a zone $zone will be disabled!"
fi
if [ -n "$ipv6" ]; then
	echo "Enabling CloudFlare IPv6 in a zone $zone!"
	curl --silent https://www.cloudflare.com/ips-v6 -o $IPV6_LIST
else
	echo "CloudFlare IPv6 in a zone $zone will not be enabled!"
fi
if [ -n "$http" ]; then
	echo "Enabling CloudFlare HTTP in a zone $zone!"
else
	echo "CloudFlare HTTP in a zone $zone will not be enabled!"
fi
if [ -n "$https" ]; then
	echo "Enabling CloudFlare HTTPS in a zone $zone!"
else
	echo "CloudFlare HTTPS in a zone $zone will not be enabled!"
fi

function_ipv4() {
	if [ -n "$http" ]; then
		while read line           
		do
				foo="rule family='ipv4' source address=\"$line\" service name='http' accept"
				firewall-cmd --permanent --zone=$zone --add-rich-rule="$foo"
		done < $IPV4_LIST
	fi
	
	if [ -n "$https" ]; then
		while read line           
		do
			foo="rule family='ipv4' source address=\"$line\" service name='https' accept"
			firewall-cmd --permanent --zone=$zone --add-rich-rule="$foo"
		done < $IPV4_LIST
	fi
}

function_ipv6() {
	if [ -n "$http" ]; then
		while read line
		do
			foo="rule family='ipv6' source address=\"$line\" service name='http' accept"
			firewall-cmd --permanent --zone=$zone --add-rich-rule="$foo"
		done < $IPV6_LIST
	fi
	
	if [ -n "$https" ]; then
		while read line
		do
			foo="rule family='ipv6' source address=\"$line\" service name='https' accept"
			firewall-cmd --permanent --zone=$zone --add-rich-rule="$foo"
		done < $IPV6_LIST
	fi
}

function_reload() {
	firewall-cmd --reload
}

function_ipv4
function_ipv6
function_reload

trap 'rm -f $IPV4_LIST $IPV6_LIST' EXIT