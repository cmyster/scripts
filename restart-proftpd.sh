#!/bin/bash
ps -ef | grep -v "grep\|bash" | grep proftpd
STATUS=$?
if [ $STATUS -ne 0 ]
then
    proftpd &
fi
