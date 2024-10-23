#!/bin/bash

# How much time to wait for an active connection
SLEEP=10

# Files that should exist:
CA="rh.crt"
CONF="tlv.conf"

if [ ! -r "$CA" ]
then
    printf "The CA file was not found!\n"
    exit 1
fi

if [ ! -r "$CONF" ]
then
    printf "The configuration file was not found!\n"
    exit 1
fi

rm -rf log
for p in $(pgrep openvpn)
do
    kill "$p" &> /dev/null
done

if [ ! -d /dev/net ]
then
    mkdir -p /dev/net
fi

if [ ! -r /dev/net/tun ]
then
    mknod /dev/net/tun c 10 200
fi

openvpn --config tlv.conf --daemon --pull-filter ignore "route-ipv6" --pull-filter ignore "ifconfig-ipv6"
echo "Waiting $SLEEP seconds to test connection."

./bar_countdown.sh $SLEEP $SLEEP "━" "┣" "┫"

if ip -f inet addr show redhat0 | grep -q UP
then
    IP=$(ip -f inet addr show redhat0 | grep "inet " | awk '{print $2}' | cut -d"/" -f 1)
    printf "\r\nup\nIP=%s\n" $IP
else
    printf "\r\ndown\n"
fi
