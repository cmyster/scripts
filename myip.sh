#!/bin/bash
IFCONFIG=$(which ifconfig)
NIC=$(route | grep ^default | awk '{print $NF}')
IP=$($IFCONFIG "$NIC" | grep "inet " | awk '{print $2}' | tr -d "addr:")
IP_FILE=~/.myip
echo "${IP}" > $IP_FILE
