#!/bin/bash
URL="https://repos.fedorapeople.org"
IMAGEPATH="/repos/openstack-m/tripleo-images-rdo-juno"
LOCAL="/home/ftp/fedorapeople.org/repos/openstack-m/tripleo-images-rdo-juno"

cd $LOCAL

lynx --dump $URL/$IMAGEPATH | grep http | grep $IMAGEPATH | grep -v "?" | awk '{print $2}' > files
for line in $(cat files)
do
    wget -Nq $line
done
