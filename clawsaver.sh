#!/bin/bash
DATE=$(date +%s)
ROOT_FOLDER=/home/augol
DST_FOLDER=$ROOT_FOLDER/gdrive/rc_files
BACKUP_NAME=claws-backup

cd $ROOT_FOLDER                                                                  
tar cf $BACKUP_NAME-$DATE.tar .claws-mail                                        
7z a $BACKUP_NAME-$DATE.7z $BACKUP_NAME-$DATE.tar &> /dev/null                   
mv $BACKUP_NAME-$DATE.7z $DST_FOLDER                                             
rm -rf $BACKUP_NAME-$DATE.tar  

TOTAL_BACKUP=$(ls -lt $DST_FOLDER/$BACKUP_NAME-* | wc -l 2> /dev/null)
HOW_MANY_BACKUPS=3

if [ $TOTAL_BACKUP -gt $HOW_MANY_BACKUPS ]
then
    TO_DELETE=$(( $TOTAL_BACKUP - $HOW_MANY_BACKUPS ))
    ls -lt $DST_FOLDER/$BACKUP_NAME-* | awk '{print $NF}' | tail -n $TO_DELETE | xargs rm -rf
fi

