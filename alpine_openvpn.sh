#!/bin/bash
for p in $(pgrep openvpn | awk '{print $1}')
do
    kill "$p"
done

if [ ! -d /dev/net ]
then
    mkdir -p /dev/net
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
    service squid stop
    service squid status
    service squid start
    service squid status

    echo "domain tlv.redhat.com
    search tlv.redhat.com redhat.com
    nameserver 10.35.255.14
    nameserver 10.38.5.26" > /etc/resolve.conf
else
    echo "no."
fi

