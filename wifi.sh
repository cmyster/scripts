#!/bin/bash

# this script would refresh establish a Wi-Fi connection.
# the script will use known info in order to connect.
# needed info:
#    interface - which of the interfaces to use.
#    ESSID - the name in which the station identifies.
#    channel - the channel number in use.
# to know whats needed, run: 
#    iwlist scan - check name and channel number
# and then save the ESSID and password:
#    wpa_passphrase <ESSID> <password> >> /etc/wpa_supplicant.conf


if [ "$(whoami)" != "root" ]
then
    echo "This script needs root privileges in order to run!"
    exit 1
fi

ARGS=("$@")
if [ ${#ARGS[@]} != 3 ]
then
    echo "usage : $0 [interface] [essid] [channel number]"
    exit 1
fi

echo "stopping $1"
ifconfig $1 down
echo "starting $1"
ifconfig $1 up
echo "setting up interface"
iwconfig $1 essid "$2" channel $3
wpa_supplicant -B -Dwext -i$1 -c/etc/wpa_supplicant.conf
echo "obtaining IP address"
dhclient $1
