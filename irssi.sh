#!/bin/bash

ps -ef | grep -v grep | grep notify-listener.py &> /dev/null
if [ $? -ne 0 ]
then
    /home/augol/bin/notify-listener.py &
fi

$(which irssi) 
