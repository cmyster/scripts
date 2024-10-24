#!/bin/bash
set -x
LOCK_FILE="/tmp/user_shutdown_script"

if [ -z "$1" ] || [ -z "$2" ]
then
    exit 1
fi

sleep $2

rm -rf $LOCK_FILE
echo shutdown "-${1}" now
