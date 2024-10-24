#!/bin/bash

# This script calls a simple script called shutdown.sh that expects exactly 2 arguments.
# Both scripts should be together in $HOME/scripts and that folder needs to be in the user's PATH.
# This way its simple to call 'sleep $1' & 'shutdown -$2 now', and if we want to cancel,
# we kill the shutdown.sh script.
#

# Usage:
print_usage ()
{
    printf "usage: %s [r (reboot) || P (Poweroff) || c (cancel)] [<uint>seconds]\n" "$0"
}

# If there are more than a single user on this machine, this script would prefer:
#    Only users in the wheel group to be able to run it.
#    Only one shutdown.sh at a time.

LOCK_FILE="/tmp/user_shutdown_script"

# Parsing the command argument, making sure its allowed; exiting if not.
# At this point we can prepare the message that will be sent via notify-send.
# If there is a single argument 'c', there is no reason to check for $2,
# but since shutdown.sh expects two parameters, we need to set it. 
# Bash does not support setting an argument from within the script,
# so first we save the argument as a variable and use that.
SEC="$2"

case "$1" in
    "r")
        export ARG="r"
        export MSG="System will reboot in $SEC seconds"
        ;;
    "P")
        export ARG="P"
        export MSG="System will power off in $SEC seconds"
        ;;
    "c")
        export ARG="c"
        export MSG="System shutdown cancelled" 
        export SEC="0"
        ;;
    *)
        print_error
        exit 1
        ;;
esac

# If the 2nd argument (time in seconds) is not set as a uint, exit.
re='^[0-9]+$'
if ! [[ $SEC =~ $re ]]
then
    print_usage
    exit 1
fi

# This script uses play from sox, notify-send and the shutdown.sh script,
# and all needs to be runnable by this user.
for app in "sox" "notify-send" "shutdown.sh"
do
    if ! command -v "$app" $> /dev/null
    then
        printf "%s is not installed!\n" "$app"
        exit 1
    fi
done

# If the current user is not in the wheel group, shutdown won't work.
if ! grep "$(whoami)" /etc/group | grep wheel &> /dev/null
then
    printf "%s is not a part of the wheel group, shutdown with no prompts can't be called\n" "$(whoami)"
    exit 1
fi
 
# If there is no shutdown.sh PID when we start the script normally based on the runtime arguments.
# If there is one, then we check the command (CMD) it was given and check what to do in each case.
#
# Command:
#     Was it set to reboot/poweroff and was changed to poweroff/reboot?
#         We stop the running script and start it again with the new command.
#     Was it set to reboot/poweroff and we set the same command again or cancel?
#         We stop the running script.

PID="$(ps | grep shutdown.sh | awk '{print $1}')"
CMD="$(ps -ef | grep shutdown | grep -v grep | rev | awk '{print $2}')"

if [ -z "$PID" ]
then
    if [ ! -f "$LOCK_FILE" ]
    then
        play -q /usr/share/sounds/freedesktop/stereo/service-logout.oga & disown
        notify-send "$MSG" & disown
        shutdown.sh "$ARG" "$SEC" & disown
        touch "$LOCK_FILE"
        exit 0
    fi
fi

if [[ "$ARG" == "c" ]]
then
    play -q /usr/share/sounds/freedesktop/stereo/service-login.oga & disown
    notify-send "$MSG" & disown
    kill "$PID"
    rm -f "$LOCK_FILE"
    exit 0
fi

set -x
if [[ "$CMD" == "$ARG" ]]
then
    play -q /usr/share/sounds/freedesktop/stereo/service-login.oga & disown
    notify-send "System shutdown cancelled" & disown
    kill "$PID"
    rm -f "$LOCK_FILE"
    exit 0
else
    if [ ! -f "$LOCK_FILE" ]
    then
        kill "$PID"
        play -q /usr/share/sounds/freedesktop/stereo/service-logout.oga & disown
        notify-send "$MSG" & disown
        shutdown.sh "$ARG" "$SEC" & disown
        touch "LOCK_FILE"
    fi
fi

