#!/bin/bash
set -x

FOREMAN_URL="https://theforeman.eng.lab.tlv.redhat.com"
METHOD="setBuild"
AUTH_USER=${AUTH_USER:-"augol"}
AUTH_PASS=${AUTH_PASS:-"Gnh,tuduk0"}
IN_HOST=$1
HPASS=$2
TMP_PING=/tmp/tmpping_$1

USAGE="$0 <hostname> <hostpass>\n
example: $0 foo.bar.com 12345\n
\n
you can also specify user name and password like so:\n
AUTH_USER=user AUTH_PASS=pass $0\n"

if [ -z $IN_HOST ] || [ -z $HPASS ]
then
    echo -e $USAGE
    exit 1
fi

if [ -z $AUTH_USER ]
then
    echo username:
    read AUTH_USER
fi

if [ -z $AUTH_PASS ]
then
    echo password:
    read -s AUTH_PASS
fi

rm -rf $TMP_PING
ping -c 1 $IN_HOST &> $TMP_PING
FOUND_HOST=$(cat $TMP_PING | grep ^PING | awk '{print $2}')
rm -rf $TMP_PING
URL="$FOREMAN_URL/hosts/$FOUND_HOST/$METHOD"

echo "setBuild on host"
curl -k -H "Accept:application/json" \
     -u ${AUTH_USER}:${AUTH_PASS} $URL &> /dev/null

echo "rebooting server"

sshpass -p $HPASS ssh root@${FOUND_HOST} reboot &> /dev/null
sleep 10

echo "starting to wait for completion"
~/scripts/tryssh.sh $FOUND_HOST
if [ $? -ne 0 ]
then
    exit 1
fi

echo "moving key and installation script"
sshpass -p $HPASS \
    ssh-copy-id -i ~/.ssh/id_rsa.pub \
    root@$FOUND_HOST &> /dev/null

scp ~/scripts/ospd.tar \
    root@$FOUND_HOST:/root/ &> /dev/null
#scp ~/scripts/packstack-install.sh \
#    root@$FOUND_HOST:/root/ &> /dev/null

echo "DONE"
