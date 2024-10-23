#!/bin/bash
IFCONFIG=$(which ifconfig)
IP_FILE=/home/augol/.myvpnip
NIC=$(grep "dev " /home/augol/gdrive/config/tlv.conf | awk '{print $NF}')
IP=$($IFCONFIG "$NIC" 2> /dev/null | grep "inet " | awk '{print $2}' | tr -d "addr:")
if [ -z "$IP" ]
then
    echo "not connected" > $IP_FILE
else
    echo "${IP}" > $IP_FILE
fi
