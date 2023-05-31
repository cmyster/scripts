#!/bin/bash
ps -ef | grep -v grep | grep -v bash | grep screen &> /dev/null
RES=$?
echo $RES
if [ $RES -eq 0 ]
then
    screen -x
else
    screen
fi
