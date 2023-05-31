#!/bin/bash

# a simple script to check if changes were made to the ChangeLog on the mirror.
# this uses date, lynx, head and curl. make sure that they are installed.
# possible status codes:
#    0 - there are no changes.
#    1 - there are changes in the ChangeLog file (so there are updates).

ZENITY=$(which zenity)
SLACKPKG=/usr/sbin/slackpkg

STATUS_FILE=/tmp/update_stat

TITLE="System Updates"
UPDATES="There are available updates"
NO_UPDATES="There are no new updates"

alert_off ()
{
    ps -ef | grep -v grep | grep "$UPDATES" &> /dev/null
    if [ $? -ne 0 ]
    then
        return 0
    else
        return 1
    fi
}

alerter ()
{
    echo "$2"
    notify-send "$1" "$2" &> /dev/null &
    zenity --info --text "$2" &> /dev/null &
    aplay /usr/share/sounds/purple/alert.wav &> /dev/null &
    exit $3
}

/usr/sbin/slackpkg check-updates | grep "No news" &> /dev/null
if [ $? -eq 0 ]
then
    echo $NO_UPDATES > $STATUS_FILE
else
    if alert_off
    then
        echo $UPDATES > $STATUS_FILE
        alerter "Updates" "There are available updates" 0
    fi

fi
