#/bin/bash
killall orage
orage -a /home/augol/mail/calendar-in.ics &
sleep 0.1
orage -t
