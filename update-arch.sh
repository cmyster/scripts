#!/bin/bash

STATUS_FILE=/tmp/update_stat
TMP_PAC=/tmp/pacman_out
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

touch $TMP_PAC

timeout 10 echo Gnh,tuduk0 | sudo -S pacman -Syu &> $TMP_PAC

grep ^Packages $TMP_PAC &> /dev/null
if [ $? -ne 0 ]
then
    echo $NO_UPDATES > $STATUS_FILE
    rm -rf $TMP_PAC
    exit 0
else
    if alert_off
    then
        echo $UPDATES > $STATUS_FILE
        alerter "Updates" "There are available updates" 0
    fi
    rm -rf $TMP_PAC
    exit 0
fi

rm -rf $TMP_PAC
