#!/bin/bash

# from 0 to 1000 (100% * 10) because its simpler to compute.
MAX_USAGE=80
PROC_NAME=dropbox
PROC_STARTER=dropboxd

is_alive ()
{
    ps -ef | grep -v grep | grep $PROC_NAME &> /dev/null
    if [ $? -eq 0 ]
    then
        return 0
    else
        return 1
    fi
}

if is_alive
then
    echo "The process \"$PROC_NAME\" is alive."
else
    echo "The process \"$PROC_NAME\" is dead."
    exit 1
fi

DB_PID=$(pgrep $PROC_NAME)

# Sometimes I don't get a PID here, no reason why.
if [ -z "$DB_PID" ]
then
    echo "I can't find ${PROC_NAME}'s PID and will exit now."
    exit 1
fi


USAGE=$(ps -p $DB_PID -o pmem | tail -n 1 | tr -d " ")
CURRENT_USAGE=$(bc<<<${USAGE}*10 | tr -d ".0")

# lets sum it all up

echo "Process name       $PROC_NAME"
echo "Process ID         $DB_PID"
echo "Process RAM usage  ${USAGE}%"
echo "Maxed allowed RAM  $(bc<<<'scale=1;'$MAX_USAGE'/10')%"

if [ $CURRENT_USAGE -gt $MAX_USAGE ]
then
    echo "$PROC_NAME is using more RAM that allowed, killing it..."
    exit 0
    kill $DB_PID
    echo "Gracefully waiting for exit."
    sleep 30
    if is_alive
    then
        echo "$PROC_NAME is still alive, killing forcibly."
        kill -9 $DB_PID
    else
        echo "$PROC_NAME is down."
    fi

    $PROC_STARTER &
    sleep 5
else
    exit 0
fi

if is_alive
then
    echo "$PROC_NAME is up."
else
    echo "$PROC_NAME did not start!"
fi

