#!/bin/bash
#
# Script to check krb status after waking up. It will wait for a while before
# starting, because I want to be sure that the user already signed in.
case "$1" in
   suspend|hibernate)
      #do nothing
   ;;
   resume|thaw)
      export DISPLAY=:0
      sleep 30
      /home/augol/scripts/krb.sh &> /home/augol/FIX/log
   ;;
   *)
      exit 1
   ;;
esac
exit 0
