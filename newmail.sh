#!/bin/bash

MAILLOG=/tmp/new-mail
TMPLOG=/tmp/new-mail-work

rm -rf $TMPLOG

TITLE="Unread mail items:"
echo $TITLE > $MAILLOG

MAIL_DIR=~/Mail/RH
COUNT=0

for dir in $(find $MAIL_DIR -type d -name new | grep -v " ")
do
    cd $dir
    NEW=$(find -type f | wc -l)
    if [ $NEW -gt 0 ]
    then
        FOLDER=$(echo ${PWD} | rev | cut -d / -f 2 | rev)
        echo $FOLDER: $NEW >> $TMPLOG
        COUNT=$(( COUNT + $NEW ))
    fi
done

if [ $COUNT -gt 0 ]
then
    # dbus notification
    sed -i 's/items:/items: '$COUNT'/g' $MAILLOG
    notify-send "NEW MAIL" "$TITLE $COUNT"

    # zenity window
    sort $TMPLOG | uniq >> $MAILLOG
    for PID in $(ps -ef | grep -v grep | grep zenity | awk '{print $2}')
    do
        kill -9 $PID
    done
    zenity --text-info --title "Unread mail items: $COUNT" --filename $MAILLOG &

    # ding
    if [ $COUNT -ne 0 ]
    then
        play /usr/share/sounds/freedesktop/stereo/message.oga
    fi
else
    sed -i 's/items:/items: 0/g' $MAILLOG
fi

rm -rf $TMPLOG
