#!/bin/bash

TMP_DIR="/tmp/bugstatus"
REPORT="$TMP_DIR/report"
TMPFILE="$TMP_DIR/tmpfile"
CNTFILE="$TMP_DIR/bugscounter"

CWD=$(dirname "$0")
export CWD

# source editable strings.
. "$CWD/strings"

# load functions.
while IFS= read -r file
do
    . "$file"
done < <(find "$CWD/functions" -name "*.sh")

LOCKFILE="$TMP_DIR/bugstatus.lock"
if [ -r $LOCKFILE ]
then
    echo "Lock file found in $LOCKFILE."
    exit 1
fi

rm -rf "$TMP_DIR"
mkdir "$TMP_DIR"

touch $LOCKFILE

YEAR=$(( $(date +%Y) - 1 ))
FROM="$YEAR-$(date +%m-%d)"
REPOPT="https://bugzilla.redhat.com/buglist.cgi?chfieldfrom=${FROM}&chfieldto=Now&f1=reporter&j_top=OR&o1=equals&v1"
INFO="https://bugzilla.redhat.com/buglist.cgi?f1=flagtypes.name&f2=bug_status&f3=qa_contact&list_id=12134656&o1=equals&o2=notequals&o3=equals&query_format=advanced&v1=needinfo%3F&v2=CLOSED&v3"
ON_QA="https://bugzilla.redhat.com/buglist.cgi?bug_status=ON_QA&qa_contact"
OPEN="https://bugzilla.redhat.com/buglist.cgi?bug_status=NEW&bug_status=ASSIGNED&bug_status=POST&bug_status=MODIFIED&bug_status=ON_DEV&f1=qa_contact&j_top=OR&o1=equals&v1"

TD="td style=\"text-align: center; height:30px; width: 80px;\""

users=(
       "amalykhi"
       "asavina"
       "augol"
       "awolff"
       "epassaro"
       "eweiss"
       "lshilin"
       "omichael"
       "prabinov"
       "rbartal"
       "rhalle"
       "smiron"
       "sserafin"
       "vvoronko"
       "yporagpa"
      )

open_html ()
{
    cat >> $TMPFILE <<EOF
<html>
<head>
  <title>Team Bugzilla Status</title>
  <meta http-equiv="refresh" content="600">
</header>
  <body>
  <p>Team overall bug status. Hover on each column header for an explanation.</p>
    <table border="1">
      <tr>
        <$TD, title="Username"><strong>UserID</strong></td>
        <$TD, title="ON QA bugs with this user as QA assignee"><strong>ON_QA</strong></td>
        <$TD></td>
        <$TD, title="All the bugs that have a need-info on this user"><strong>Need info</strong></td>
        <$TD></td>
        <$TD, title="All bugs that are open with this user as QA assignee that are not yet fixed"><strong>Open bugs</strong></td>
        <$TD></td>
        <$TD, title="All the bugs that this user have opened in the past year"><strong>Reported bugs (Y)</strong></td
        <$TD></td>
      </tr>
EOF
}

get_queue ()
{
    LINK="$1=${2}%40redhat.com"
    BUGS=$(bugzilla query --field=limit=0 --from-url "$LINK" | wc -l)
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
    TOTAL_LINE="<$TD><strong>Total</strong></td>"
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

open_html
for user in "${users[@]}"
do
    echo "<tr>" >> $TMPFILE
    echo "<$TD>${user%\%*}</td>" >> $TMPFILE
    get_queue "$ON_QA" "$user"
    get_queue "$INFO" "$user"
    get_queue "$OPEN" "$user"
    get_queue "$REPOPT" "$user"
    echo "</tr>" >> $TMPFILE
done

add_totals

close_html

mv $TMPFILE $REPORT

sendmail augol-all@redhat.com <<EOF
$(echo "Subject: Team Bug report")
$(echo "Content-Type: text/html")
$(echo "Mime-Version: 1.0")
$(echo "To: augol-all@redhat.com")
$(echo "From: augol@redhat.com")
$(cat "$REPORT")
EOF

rm -rf "$TMP_DIR"
