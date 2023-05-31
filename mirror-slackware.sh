#!/bin/bash

# PARAMETERS

LOGPATH="/var/log/mirroring/slackware"
LASTRUN=$LOGPATH/last_slackware_sync
SCRIPT="/root/scripts/aliens_mirroring.sh"
RUNTIME=$(date +%d-%m-%Y_%H%M%S)
VERSIONS=( "current" )
ARCHS=( x86_64 )
RECENT_CHANGES="/var/www/htdocs/slackware_recent_changes.txt"
H_LINE="---------------------------------------------"
TMP_LOG="/tmp/tmp_last_changes"

# FUNCTIONS

function mirror ()
{
    for VERSION in ${VERSIONS[@]}
    do
        for ARCH in ${ARCHS[@]}
        do
            LOGFILE=$LOGPATH/slackware-$VERSION-$ARCH-$RUNTIME.log
            echo Starting sync at $(date) > $LOGFILE
            echo $H_LINE >> $LOGFILE
            $SCRIPT -f -a $ARCH -r $VERSION >> $LOGFILE
        done
    done
}

function generate_changes ()
{
    for DIR in $(ls -1 | grep -v iso)
    do
        cd $DIR
        if [ $(date -r ChangeLog.txt +%s) -gt $(cat $LASTRUN) ]
        then
            for LINE in {1..200}
            do
                sed -n ${LINE}p ChangeLog.txt | grep "+---" > /dev/null
                if [ $? -eq 0 ]
                then
                    STOPLINE=$(( LINE - 1 ))
                    break
                fi
            done
            CHANGES=$(head -n $STOPLINE ChangeLog.txt | grep -v '^[[:space:]]' | wc -l)
            if [ $CHANGES -gt 1 ]
            then
                FINAL="changes are"
            else
                FINAL="change is"
            fi

            echo "In $DIR the $FINAL:" > $TMP_LOG
            head -n $STOPLINE ChangeLog.txt >> $TMP_LOG
            echo $H_LINE >> $TMP_LOG
            cat $RECENT_CHANGES >> $TMP_LOG
            mv $TMP_LOG $RECENT_CHANGES
            sed -i -r '1i\\' $RECENT_CHANGES
            sed -e '1iLast updated at: '"$(date)"'\' -i $RECENT_CHANGES
        fi
        cd ..
    done
}

# MAIN

if [ ! -r $LASTRUN ]
then
    rm -rf $LASTRUN
    date +%s > $LASTRUN
fi
mirror
MIRRORROOT=$(grep "{SLACKROOTDIR:-" $SCRIPT | awk -F\" '{print $2}')
cd $MIRRORROOT
generate_changes

date +%s > $LASTRUN
