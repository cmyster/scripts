#!/bin/bash

set -x

VERSIONS=(
          "5.5"
          "5.6"
          "5.7"
          "5.8"
          "5.9"
          "5.10"
          "5.11"
         )

set_latest_version ()
{
URL="http://file.cloudforms.lab.eng.rdu2.redhat.com/builds/cfme/${1}/stable/"
TMP="/tmp/mirroring/cfme_${1}_stable"
DIR="/home/ftp/cfme/${1}/stable"
LOG="/var/log/mirroring/cfme/${1}/mirroring-cfme-${1}-stable-$(date +%s).log"

if [ ! -d $(dirname $LOG) ]
then
    mkdir -p $(dirname $LOG)
fi

if [ ! -d $DIR ]
then
    mkdir -p $DIR
fi

cd $DIR

ONLINE_IMG=$(curl -s --list-only $URL | grep rhos | grep "\.qcow2" | sed -r 's/^.+href="([^"]+)".+$/\1/')
CURRENT_IMG=$(ls -1 *.qcow2 | sort -hr | head -n 1)
BIGGER=$(echo -ne "$ONLINE_IMG\n$CURRENT_IMG" | sort -V | tail -n 1)
echo "Local image: $CURRENT_IMG" >> $LOG
echo "Online image: $ONLINE_IMG" >> $LOG

if [ "$BIGGER" != "$CURRENT_IMG" ]
then
    echo "Online image is different." >> $LOG
    echo "Downloading $ONLINE_IMG." >> $LOG
    wget -q -nc $URL/$ONLINE_IMG || exit 1
    echo "Removing $CURRENT_IMG." >> $LOG
    rm -rf $CURRENT_IMG
    echo "Linking $ONLINE_IMG as 'latest'." >> $LOG
    unlink latest &> /dev/null
    ln -s $ONLINE_IMG latest
else
    echo "Current image is up-to-date." >> $LOG
fi
}

for minor in ${VERSIONS[@]}
do
    set_latest_version $minor
done
