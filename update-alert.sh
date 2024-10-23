#!/bin/bash
COUNTFILE=/tmp/update_stat

if [ -z "$(cat $COUNTFILE)" ]
then
    exit 0
else
    export DISPLAY=:0
    kdialog --title "System Updates" --textbox $COUNTFILE 300 10
fi
