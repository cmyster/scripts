#!/bin/bash
set -x

TMP_EVENT=/tmp/next_event
START=$(date -d "now" +%T)
END=$(date -d "now + 11 minutes" +%T)
gcalcli --nocolor agenda --military "$START" "$END" | grep -v "^$" 1> "$TMP_EVENT"
TEXT="$(cat $TMP_EVENT)"

if [[ "$TEXT" == "No Events Found..." ]]
then
    exit 0
fi


play /usr/share/sounds/freedesktop/stereo/dialog-warning.oga &> /dev/null &
yad \
    --escape-ok \
    --no-buttons \
    --geometry=260x20 \
    --top \
    --center \
    --text "$TEXT" \
    --title "Upcoming Meeting" & &> /dev/null

notify-send -a echo "$TEXT" &> /dev/null &
