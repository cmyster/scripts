#!/bin/bash

# starting a few things after a few seconds. Sometimes applications do not
# start correctly and need other resources to be available.

sleep 5

/usr/bin/hexchat --minimize=2 &
/usr/bin/thunderbird &
/usr/bin/irexec &

/home/augol/scripts/krb.sh &
