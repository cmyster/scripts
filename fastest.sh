#!/bin/bash
LOG_FILE=log.txt
# 32 or 64 bit? (if 32, set to empty string)
ARCH=64
# slackware version?
VERSION=current
# path to a 1MB file. I use tar, which is close to it
PACK_PATH=slackware$ARCH/a/tar-1.26-x86_64-1.tgz
# list of mirrors, from the mirrors file and depends on ARHC and VERSION
MIRRORS=$(cat /etc/slackpkg/mirrors | grep --color=none $ARCH | grep --color=none $VERSION | sed 's/# //g')
# setting up a best time for each mirror to set, this is set to 999.999... (s)
BEST_TIME=999999999999
# setting the best mirror to beat
BEST_MIRROR="no-way"
for MIRROR in $MIRRORS
do
    START_TIME=$(date +%s%N)
    wget -T 30 -t 1 $MIRROR$PACK_PATH
    STATUS=$?
    END_TIME=$(date +%s%N)
    rm -rf tar*.tgz
    TOTAL_TIME=$(( $END_TIME - $START_TIME ))
    if [ $STATUS != 0 ]
    then
        continue
    fi
    if [[ $TOTAL_TIME -lt $BEST_TIME ]]
    then
        export BEST_TIME=TOTAL_TIME
        export BEST_MIRROR=$MIRROR
    fi
done

echo $BEST_MIRROR &> $LOG_FILE
