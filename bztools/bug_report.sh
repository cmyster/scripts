#!/bin/bash

# This script will send a report about KNI bugs which are missing certain
# elements and send a report of what's missing.
# Requires:
# * python-bugzilla installed, working, and that you logged in with it using
# * your Red Hat's credentials at least once:
# * https://blog.wikichoon.com/2019/01/python-bugzilla-bugzilla-50-api-keys.html
# * Optional: a working MTA that gives you a sendmail command.

# Static variables (strings) are in the "strings" file.

# Disableing ShellCheck's error SC1090 since I don't want to pass static URI.
# shellcheck source=/dev/null

CWD="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
export CWD

. "$CWD/strings"

# Source function files.
while IFS= read -r file
do
    . "$file"
done < <(find "$CWD/functions" -name "*.sh")

# Define the runtime arguments that are used to determin the pillar.
set_pillar "$1" "$2"

# !Any other functions should be defined in ./functions/ and called below!

# Initialize the working directory and report.
init_workdir
init_report

# Before we run an extensive BZ query that requires full credentials, run a
# sinple check
if ! check_login
then
    echo "Couldn't get valid credentials. Can't continue."
    exit 1
fi

# We want to return the raw output of the URL query. Since this is the most
# time consuming operation (can take a few minutes), we dump everything now
# to a large file, split it to one file per bug and take info" out of that
# file using grep to build the final report.
gen_raw_bz_data raw
break_raw
exit 0

# After processing any bug, set the send mail flag accordingly. Only send a
# report if there is at least one bug on the report. This flag will be
# updated while processing bugs so we declare it here.
export SEND_MAIL=false

# Now lets go over each bug and process it to see if there are issues.
case $TYPE in
    "MISSING")
        analyze_bugs_missing
        ;;
    "LIFECYCLE")
        analyze_bugs_lifecycle
        ;;
esac

# Changing the FINDWORDS in the report to indicate the number of bug(s), and
# to update the pillar's name
case $TYPE in
    "MISSING")
        finilize_report_missing
        ;;
    "LIFECYCLE")
        finilize_report_lifecycle
        ;;
esac

# Lastly, regardless if we would like to send the mail or not, if there is no
# sendmail, don't try to send anything.
if ! [ -x "$(command -v sendmail)" ]
then
    export SEND_MAIL=false
fi

# Send the report but only if it has at least one bug. The mail is send to
# what's configures in TO.
if $SEND_MAIL; then
    send_mail
fi
