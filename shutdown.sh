#!/bin/bash

CANCEL=false
if [[ "$1" == "c" ]]
then
    CANCEL=true
fi

if $CANCEL
then
    notify-send -u normal "Shutdown aborted"
else
    play -q /usr/share/sounds/freedesktop/stereo/service-logout.oga & disown
    notify-send -u critical "System shutdown in $1 seconds!"
    sleep $1 && shutdown -P now
fi

