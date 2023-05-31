#!/bin/bash
/home/augol/.local/bin/gcalcli agenda \
    "$(date)" 23:59 \
    --military \
    | sed "s,\x1B\[[0-9;]*[a-zA-Z],,g" \
    | sed "s|$(date +"%a %b %d")||g" \
    | grep -v ^$ \
    | awk '{print $1" "$2" "$3" "$4" "$5" "$6" "$7" "$8}' > /home/augol/.gcal
