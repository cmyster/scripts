#!/bin/bash

RC6="/etc/rc.d/rc.6"

if grep -e "find.*mindepth.*xargs" $RC6 &> /dev/null
then
    echo "No need to modify $RC6"
    exit 0
fi

UMOUNT_LINE=$(grep -nr "bin.*unmount" $RC6 | tail -n 1 | cut -d ":" -f 1)
CLEAN_CMD="$((UMOUNT_LINE - 1))i find /tmp -type d -mindepth 1 | xargs rm -rf\nfind /var/tmp -type d -mindepth 1 | xargs rm -rf\nfind /usr/tmp -type d -mindepth 1 | xargs rm -rf\nfind /var/cache -type d -mindepth 1 | xargs rm -rf\n"
sed -i "$CLEAN_CMD" $RC6
