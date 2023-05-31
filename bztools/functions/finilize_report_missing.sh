#!/bin/bash

finilize_report_missing ()
{
    cat "$CWD/htmlend" >> "$REPORT"
    bugs=$(grep -c "bugzilla.redhat.com" "$REPORT")
    if [ "$bugs" -eq 1 ]
    then
        sed -i 's/FINDBUGS/bug/' "$REPORT"
    else
        sed -i 's/FINDBUGS/bugs/' "$REPORT"
    fi

    sed -i "s/FINDBUGNUM/$bugs/" "$REPORT"
    sed -i "s/FINDPILLAR/$NAME/" "$REPORT"
}
