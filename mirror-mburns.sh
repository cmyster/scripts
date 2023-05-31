#!/bin/bash

LOCK_FILE="/var/lock/mirroring/puddle-images.lock"
REMOTE_HOST="rhos-release.virt.bos.redhat.com"
LOCAL_HOST="ikook.tlv.redhat.com"
REMOTE="/var/www/html/puddle-images"
LOCAL="/home/augol/mirror"
LOCAL_SITE_PATH="/var/www/htdocs"
RUNTIME=$(date +%d-%m-%Y_%H%M%S)
LOGPATH="/var/log/mirroring/puddle-images"
LOGFILE=$LOGPATH/puddle-images_${RUNTIME}.log
RECENT_CHANGES="${LOCAL}/puddle-images_recent_changes.html"
TMP="/tmp/mirroring/puddle-images"
SCRIPT="rsync -avz -e ssh $REMOTE augol@${LOCAL_HOST}:${LOCAL}"

mkdir -p $LOGPATH
touch $LOGFILE
unlink $LOGPATH/latest.log 2> /dev/null
ln -s $LOGFILE $LOGPATH/latest.log

echo "Starting sync at:" >> $LOGFILE
echo "$(date)" >> $LOGFILE
echo "----------------------------------------------" >> $LOGFILE

if [ -r $LOCK_FILE ]
then
    echo "found lock file ${LOCK_FILE}. aborting." >> $LOGFILE
    exit 1
fi

touch $LOCK_FILE

rm -rf $TMP
mkdir -p $TMP

cd ${LOCAL}/puddle-images

echo "getting old files" >> $LOGFILE
find &> $TMP/puddle-images-old-files

source /home/augol/.mrashrc
sshpass -e ssh augol@$REMOTE_HOST "${SCRIPT}" >> $LOGFILE
unset SSHPASS

echo "getting new files" >> $LOGFILE
find &> $TMP/puddle-images-new-files

diff $TMP/puddle-images-old-files $TMP/puddle-images-new-files &> /dev/null
if [ $? -ne 0 ]
then
    /home/augol/scripts/makediff.sh \
        $TMP/puddle-images-new-files \
        $TMP/puddle-images-old-files \
        $TMP/puddle-images_changes.html &> /dev/null

    mv $TMP/puddle-images_changes.html $LOCAL
    sed -i 's/808080/000000/g' $LOCAL/puddle-images_changes.html
fi

rm -rf $LOCK_FILE

echo "DONE" >> $LOGFILE
