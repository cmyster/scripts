#!/bin/bash
DOMAIN=download.lab.bos.redhat.com
TEST="Can't find"
nslookup $DOMAIN | grep "$TEST" &> /dev/null
if [ $? -eq 0 ]
then
    sudo killall vpnc 2> /dev/null
    sudo vpnc
else
    exit 0
fi
