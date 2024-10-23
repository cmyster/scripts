#!/bin/bash

if [ ! -r "$1" ]
then
    echo cannot read \"$1\"
    exit 1
fi

REMOTE_IP=$(who | grep $(whoami) | tr "(" " " | tr ")" " " | awk '{print $NF}' | head -n 1)
REMOTE_USER="augol"
REMOTE_DIR="/home/$REMOTE_USER"

scp $1 $REMOTE_USER@$REMOTE_IP:$REMOTE_DIR

