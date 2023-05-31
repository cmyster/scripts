#!/bin/bash

send_mail ()
{
    SUBJECT=${SUBJECT/FINDPILLAR/$NAME}
    sendmail "$TO" <<EOF
$(echo $SUBJECT)
$(echo "Content-Type: text/html")
$(echo "Mime-Version: 1.0")
$(echo To:$TO)
$(echo $FROM)
$(cat "$REPORT")
EOF
}
