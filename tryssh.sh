#!/bin/bash

# I assume that when a server is mostly up and operable I should at least be
# be able to login via SSH. Obviously, SSHD must be enabled for this to work.
#
# nc can open a port (SSH = 22) and then send data.
# nc will try for 3 seconds before quitting.
# When successful, nc will keep the port open and will wait for input and this
# freezes the script's progress. Instead, the test text is dumped into
# the open port. This verifies that the port is open, and that SSHD on the
# other side is working, as it is rejecting the bad data and closing the
# connection as expected.
#
# Required: notify-send (desktop notification)
#           zenity (a window that will stay open)
#           play (to play a sound)
#           ping (pinging the host beforehand so we don't waste time here)
#           nc (open connection and send false data)
#           .../sounds/purple/alert.wav (many distros has it by default)

# Start Time
START_TIME=$(date +%s)
HOST=$1

# Applications and files needed in this script
#DEP_APPS=( ping notify-send play nc )
#DEP_APPS=( ping play nc )
DEP_FILES=( /usr/share/sounds/freedesktop/stereo/message.oga )

# Test string for nc to send
TEST_FILE=/tmp/nc_test_string_$HOST
echo "Hello, is it me you're looking for?" > $TEST_FILE

exiter ()
{
    # Exit function to clean stuff before exiting
    rm -rf $TEST_FILE
    rm -rf $TMPFILE
    exit $1
}

# Script is expecting a single argument
ARGS=("$@")
if [ ${#ARGS[@]} -ne 1 ]
then
    echo "Usage: $0 [hostname]"
    exiter 1
fi

printer ()
{
    # Working like that gives me the option to update the screen without
    # using a new line.
    echo -n "$1"
    echo -ne "\r"
}

waiter ()
{
    # If ping returns something other then 0 then it cannot connect. If
    # it cannot connect now, it might be doing something like booting
    # up. I want to let it do it up to 180s and checking once every
    # minute to see if the connection is up, wheres I'll start checking
    # it with nc.
    if test_connection
    then
        wait_for_connection
    else
        SEC=59
        TRIES=3
        echo "Trying for $(( $SEC + 1 )) seconds in $TRIES attempts"
        for attempt in $(seq 1 $TRIES)
        do
            for i in $(seq 0 $SEC)
            do
                printer "Attempt: $attempt ; Waiting for $(($SEC - $i + 1 )) seconds"
                sleep 1
            done
            printer "Attempt: $attempt ; Waiting for 0 seconds"
            if test_connection
            then
                wait_for_connection
                break
            fi
        done
    fi
}

# Input should be reachable from this network
test_connection ()
{
    ping -q -c 1 $HOST &> /dev/null
    return $?
}

# Print dependency error
dep_error ()
{
    echo "$1 was not found"
    exiter 1
}

# This is where the alerts happen
alerter ()
{
    echo
    echo "$2"
    #notify-send "$1" "$2" &> /dev/null &
    #zenity --info --text "$2" &> /dev/null &
    #play /usr/share/sounds/freedesktop/stereo/message.oga &> /dev/null &
    TOTAL_TIME=$(( $(date +%s) - START_TIME ))
    echo "Waited for a total of $(date -u -d  @${TOTAL_TIME} +%X)"
    exiter "$3"
}

# Testing needed stuff
deps_test ()
{
    for DEP_APP in "${DEP_APPS[@]}"
    do
        if which "$DEP_APP" &> /dev/null
        then
            dep_error "$DEP_APP"
        fi
    done

    for DEP_FILE in "${DEP_FILES[@]}"
    do
        if [ ! -f "$DEP_FILE" ]
        then
            dep_error "$DEP_FILE"
        fi
    done
}

# This is the waiting job
wait_for_connection ()
{
    # (1800 x 1) = 1800s = 30m. Should be enough for a server to be started
    ITER=1800
    SLEEP=1
    TMPFILE=/tmp/nc_tmpfile_
    PORT=22
    echo "Waiting up to $(date -u -d  @${ITER} +%X)"
    for i in $(seq 0 $ITER)
    do
        printer "Waiting for $(date -u -d  @${i} +%X)"
        nc -w 1 $HOST $PORT < $TEST_FILE &> $TMPFILE
        grep OpenSSH $TMPFILE &> /dev/null
        if [ $? -eq 0 ]
        then
            MSG="SSH on $2 is open"
            TITLE="Server UP"
            rm -rf $TMPFILE
            alerter "$TITLE" "$MSG" 0
        fi

        if [ $i -eq $ITER ]
        then
            MSG="Cannot connect to server!"
            TITLE="Connection Timeout"
            rm -rf $TMPFILE
            alerter "$TITLE" "$MSG" 1
        fi

        sleep $SLEEP
    done
}
# testing for dependency issues
deps_test

# testing that the host is accessible from this machine
echo "Initial ping test on $HOST"
waiter

# waiting for the host to have port 22 opened
wait_for_connection $TEST_FILE $1

