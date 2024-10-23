#!/bin/bash

STATUSFILE=/home/ftp/files/bugstatus.html
TMPFILE=/tmp/bugstatus
TMPQUEU=/tmp/tmpqueue
CNTFILE=/tmp/bugscounter
LOCKFILE=/tmp/bugstatus.lock
LOGFILE=/tmp/bugstatus.log

logger ()
{
    echo "$1" >> $LOGFILE
}

print_border ()
{
    logger "====================================="
}

print_border
logger "Started at $(date)"

if [ -r $LOCKFILE ]
then
    logger "Lock file found in $LOCKFILE."
    exit 1
fi

touch $LOCKFILE

rm -rf $TMPFILE $CNTFILE $TMPQUEU

REPOPT="https://bugzilla.redhat.com/buglist.cgi?f1=reporter&j_top=OR&o1=equals&v1"
INFO="https://bugzilla.redhat.com/request.cgi?action=queue&requestee"
ON_QA="https://bugzilla.redhat.com/buglist.cgi?bug_status=ON_QA&qa_contact"
OPEN="https://bugzilla.redhat.com/buglist.cgi?bug_status=NEW&bug_status=ASSIGNED&bug_status=POST&bug_status=MODIFIED&bug_status=ON_DEV&f1=qa_contact&j_top=OR&o1=equals&v1"

TD="td nowrap height=\"30\", width=\"100\""

users=(
       "amalykhi"
       "augol"
       "dmaizel"
       "eweiss"
       "lshilin"
       "nsharabi"
       "omichael"
       "osherman"
       "prabinov"
       "rbartal"
       "smiron"
       "ssmolyak"
       "vvoronko"
      )

open_html ()
{
    DATE=$(date +%d/%m\ %T)
    cat >> $TMPFILE <<EOF
<html>
<head>
  <title>Bugzilla status</title>
  <meta http-equiv="refresh" content="600">
</header>
  <body>
  <p>Updated to: $DATE</p>
    <table border="0">
      <tr>
        <$TD, title="Username">UserID</td>
        <$TD, title="ON QA bugs with this user as QA assignee">ON_QA</td>
        <$TD></td>
        <$TD, title="All the bugs that have a need-info on this user">Need info</td>
        <$TD></td>
        <$TD, title="All bugs that are open with this user as QA assignee that are not yet fixed">Open bugs</td>
        <$TD></td>
        <$TD, title="All the bugs that this user have opened">Reported bugs</td>
        <$TD></td>
      </tr>
EOF
}

get_queue ()
{
    LINK="$1=${2}%40redhat.com"
    lynx -dump "$LINK" > $TMPQUEU
    BUGS=$(lynx -dump "$LINK" | grep show_bug | awk '{print $NF}' | uniq | wc -l)
    eval NUM=\$"${3}"
    echo "<$TD>$BUGS</td>" >> $TMPFILE
    if [ "$BUGS" -eq 0 ]
    then
        echo "<$TD></td>" >> $TMPFILE
    else
        echo "<$TD><a target=_blank href=\"$LINK\">link</a></td>" >> $TMPFILE
    fi
    echo "$BUGS" >> "$CNTFILE"
}

add_totals ()
{
    echo "<tr>" >> $TMPFILE
    TOTAL_LINE="<$TD>Total</td>"
    for i in $(seq 1 4)
    do
        TOT=$(sed -n "${i}~4p" $CNTFILE | paste -s -d+ | bc)
        TOTAL_LINE="$TOTAL_LINE<$TD>$TOT</td><$TD></td>"
    done
    echo "$TOTAL_LINE" >> $TMPFILE
    echo "</tr>" >> $TMPFILE
}

close_html ()
{
    cat >> $TMPFILE <<EOF
    </table>
  </body>
</html>
EOF
}
logger "Generating a new HTML."
sed -i "/Updated/c <p>Started rebuilding at $(date +%d/%m\ %T)</p><p>This can take a few minutes.</p><p>The page will be updated when its done.</p>" $STATUSFILE
open_html
for user in "${users[@]}"
do
    logger "Now gathering numbers on ${user}."
    echo "<tr>" >> $TMPFILE
    echo "<$TD>${user%\%*}</td>" >> $TMPFILE
    get_queue "$ON_QA" "$user"
    get_queue "$INFO" "$user"
    get_queue "$OPEN" "$user"
    get_queue "$REPOPT" "$user"
    echo "</tr>" >> $TMPFILE
done

add_totals

logger "Finilizing HTML."

close_html

mv $TMPFILE $STATUSFILE
rm $LOCKFILE
logger "Ended at $(date)"

