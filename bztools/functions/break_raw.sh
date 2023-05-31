#!/bin/bash

break_raw ()
{
    while IFS= read -r line
    do
        if echo "$line" | grep -Eq "^Bugzilla [0-9]{7}:"
        then
            BZ_ID=$(echo "$line" | cut -d " " -f 2 | tr -d ":")
            export BZ_ID
            export BZ_FILE="${BZ_ID}.raw"
            if [ -z "$BZ_FILE" ]
            then
                echo "$line"
                exit 0
            fi
        fi
        echo "$line" >> "$BZ_FILE"
    done < <(cat raw)
    unset BZ_ID
    unset BZ_FILE
}
