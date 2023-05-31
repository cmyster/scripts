#!/bin/bash

rm -rf log
for p in $(pgrep openvpn)
do
    kill "$p" &> /dev/null
done

chmod +x /etc/rc.d/rc.squid
/etc/rc.d/rc.squid stop

if [ ! -d /dev/net ]
then
    mkdir -p /dev/net
fi

if [ ! -d /var/cache/squid ]
then
    mkdir -p /var/cache/squid
    chmod 0777 /var/cache/squid
fi

if [ ! -r /dev/net/tun ]
then
    mknod /dev/net/tun c 10 200
fi

rm -rf log
openvpn --verb 6 --log log --config /etc/openvpn/tlv.conf --daemon
sleep 15
if pgrep openvpn &> /dev/null
then
    echo "Openvpn process is up."
    echo "domain tlv.redhat.com
    search tlv.redhat.com redhat.com
    nameserver 10.35.255.14
    nameserver 10.38.5.26" > /etc/resolve.conf

    /etc/rc.d/rc.squid start
else
    echo "Openvpn process is down."
fi
echo "Network redhat0:"
ifconfig redhat0 | grep "inet "

chmod -x /etc/rc.d/rc.squid
