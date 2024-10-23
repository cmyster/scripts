#!/bin/bash

RELEASE=current

LINKS=$(grep $RELEASE /etc/slackpkg/mirrors | awk '{print $2"/ChangeLog.txt"}')
INDEX=0
for LINK in $LINKS
do
    wget -O ChangeLog$INDEX.txt -t 1 $LINK
    export INDEX=$(( $INDEX + 1 ))
done
