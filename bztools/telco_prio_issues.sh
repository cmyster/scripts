#!/bin/bash


# Requires:
#    a working MTA that gives you a sendmail command.
#    a local copy of kni-devel cloned with offlineimap.
#    python-bugzilla installed and working (logged in at least once).

CWD=$(dirname "$0")
export CWD

. "$CWD/strings"

# Fixed strings are set in this area.
WORK_DIR=/tmp/customer_cases
REPORT_TMP="report_temp"
REPORT_FIN="report"
SUBJECT_SEND="Subject: customer case bugs waiting for QE closed loop"
BUG_URL="https://bugzilla.redhat.com/show_bug.cgi?id="

# Source function files.
while IFS= read -r file
do
    . "$file"
done < <(find "$CWD/functions" -name "*.sh")

# Before we start we need to make sure that the credentials are working.
if ! check_login
then
    echo "Bad credentials, Can't continue."
    exit 1
fi

# Make sure the work directory is there and empty.
if [ ! -d "$WORK_DIR" ]
then
    mkdir "$WORK_DIR"
fi

cd $WORK_DIR || exit 1
rm -rf ./*
echo "This is an automatic report that is being generated from customer cases.
It is expected that customer cases would undergo a closed loop process,
even if the bug is on CLOSED state.
For more information regarding closed loop process please have a look at:
https://source.redhat.com/groups/public/qe_data/quality_engineering_metrics_and_analytics_wiki/customer_ticket_to_test_closed_loop_process_simplified

A total of FINDBUGNUM FINDBUGS have something missing:" > "$REPORT_TMP"

# Each time we find an issue in a bug, tmp counter gets a +1. The BZ summary
# and URL are written only once, if the counter was at 0 (first time that a
# problem was identified). The end result will be bug summary, URL, QA
# contact and a list of issues associated to it below.
report_issue ()
{
    if [ "$1" -eq 0 ]
    then
        printf "%b\n" \
            "\nSummary: $2" \
            "URL: $3" \
            "QA contact: $4" \
            "Contact's e-mail: $5" \
            "Issue: $6" >> $REPORT_TMP
    fi
}

# TCB_BZ_Q has a query that looks for any bug that has a customer case
# attached to it. This is how we know that a bug was raised by a customer.
# TCB is focused only on bugs whos QA Contact are in Ecosystem QE.
#bugzilla query --field=limit=0 --from-url "$TCB_BZ_Q" --json > "json"
bugzilla query --field=limit=0 --from-url "https://bugzilla.redhat.com/buglist.cgi?f1=cf_internal_whiteboard&f2=version&o1=substring&o2=equals&product=OpenShift%20Container%20Platform&query_format=advanced&v1=Telco&v2=4.3.0" --json > "json"
sleep 10
bugzilla query --field=limit=0 --from-url "https://bugzilla.redhat.com/buglist.cgi?f1=cf_internal_whiteboard&f2=version&o1=substring&o2=equals&product=OpenShift%20Container%20Platform&query_format=advanced&v1=Telco&v2=4.4" --json >> "json"
sleep 10
bugzilla query --field=limit=0 --from-url "https://bugzilla.redhat.com/buglist.cgi?f1=cf_internal_whiteboard&f2=version&o1=substring&o2=equals&product=OpenShift%20Container%20Platform&query_format=advanced&v1=Telco&v2=4.5" --json >> "json"
sleep 10
bugzilla query --field=limit=0 --from-url "https://bugzilla.redhat.com/buglist.cgi?f1=cf_internal_whiteboard&f2=version&o1=substring&o2=equals&product=OpenShift%20Container%20Platform&query_format=advanced&v1=Telco&v2=4.6" --json >> "json"
sleep 10
bugzilla query --field=limit=0 --from-url "https://bugzilla.redhat.com/buglist.cgi?f1=cf_internal_whiteboard&f2=version&o1=substring&o2=equals&product=OpenShift%20Container%20Platform&query_format=advanced&v1=Telco&v2=4.7" --json >> "json"
sleep 10
bugzilla query --field=limit=0 --from-url "https://bugzilla.redhat.com/buglist.cgi?f1=cf_internal_whiteboard&f2=version&o1=substring&o2=equals&product=OpenShift%20Container%20Platform&query_format=advanced&v1=Telco&v2=4.8" --json >> "json"
sleep 10
bugzilla query --field=limit=0 --from-url "https://bugzilla.redhat.com/buglist.cgi?f1=cf_internal_whiteboard&f2=version&o1=substring&o2=equals&product=OpenShift%20Container%20Platform&query_format=advanced&v1=Telco&v2=4.9" --json >> "json"
sleep 10
bugzilla query --field=limit=0 --from-url "https://bugzilla.redhat.com/buglist.cgi?f1=cf_internal_whiteboard&f2=version&o1=substring&o2=equals&product=OpenShift%20Container%20Platform&query_format=advanced&v1=Telco&v2=4.10" --json >> "json"
sleep 10
bugzilla query --field=limit=0 --from-url "https://bugzilla.redhat.com/buglist.cgi?list_id=12719052&product=Red%20Hat%20Advanced%20Cluster%20Management%20for%20Kubernetes" --json >> "json"
# With all bugs dumped to a file, we need to break it. The reason why we
# break it instead of running it one at a time is for simplicity later.
break_json

# After processing any bug, set the send mail flag accordingly. Only send the
# report if there is at least a single bug in it. This flag will be updated
# while processing bugs, so we declare it outside of the loop.
SEND_MAIL=false

# Processing bugs:
#     A "customer bug" needs to have the flag qe_test_coverage set:
#         '?' - we need to investigate, and if needed, work on it (see docs).
#         '-' - we have investigated and there is nothing for us to do here.
#         '+' - we have a completed the process on the specific bug.
#         ' ' - if it is empty, we havn't even started.
#     If the bug's qe_test_coverage is not set or still on '?', we get the
#     assigned QA details and create a report from that.
while IFS= read -r bug
do
    # tmp is an issue counter. Only the first time a problem was found the
    # bugs summary and URL will be written.
    tmp=0

    id=$(grep -E "^      \"id\":" "$bug" | awk '{print $NF}' | tr -d ",")

    # Getting the bug's summary.
    summary=$(grep -E "\"summary\":" "$bug" | sed 's/      "summary": //g' | sed 's/,$//g')

    # Getting the QA contact.
    qa_contact_email=$(grep -A4 qa_contact_detail "$bug" | grep -E "\"email\"" | tr -d '",' | awk '{print $NF}')
    qa_contact_realname=$(grep -A4 qa_contact_detail "$bug" | grep -E "\"real_name\"" | tr -d '",' | awk '{print $2" "$3" "$4" "$5" "$6}')

    # qe_test_coverage needs to have either '+' or '-'.
    qe_test_coverage=$(grep -A2 qe_test_coverage "$bug" | grep -E "\"status\"\:" | tr -d '",' | awk '{print $NF}')
    case "$qe_test_coverage" in
        +) continue ;;
        -) continue ;;
        ?)
            report_issue \
                "$tmp" \
                "$summary" \
                "${BUG_URL}$id" \
                "$qa_contact_realname" \
                "$qa_contact_email" \
                "qe_test_coverage is still in progress."
            tmp=$(( tmp + 1 ))
            ;;
        *)
            report_issue \
                "$tmp" \
                "$summary" \
                "${BUG_URL}$id" \
                "$qa_contact_realname" \
                "$qa_contact_email" \
                "qe_test_coverage flag is not set."
            tmp=$(( tmp + 1 ))
            ;;
    esac

    # If we found at least a single issue, set the sending mail flag to true.
    if [ $tmp -gt 0 ]
    then
        export SEND_MAIL=true
    fi
done < <(find . -maxdepth 1 -mindepth 1 -name "*.json")

# Changing the FINDWORDS in the report to indicate the number of bug(s).
bugs=$(grep -c "Summary:" "$REPORT_TMP")
if [ "$bugs" -eq 1 ]
then
    sed -i 's/FINDBUGS/bug/' "$REPORT_TMP"
else
    sed -i 's/FINDBUGS/bugs/' "$REPORT_TMP"
fi

sed -i "s/FINDBUGNUM/$bugs/" "$REPORT_TMP"

# It would be faster and easier to remove the initial empty bug report then
# to try and look for what the first request is in a loop.

head -n -6 "$REPORT_TMP" > "$REPORT_FIN"

# Send the report but only if it has at least one bug. The mail is send to
# all QA contacts and CC to what's set above.
#if $SEND_MAIL; then
#    TO=$(grep -E "Contact's e-mail: " report | grep redhat | awk '{print $NF}' | sort | uniq | tr "\n" ",")
#    sendmail "$TO" <<EOF
#$(echo $SUBJECT_SEND)
#$(echo To:$TO)
#$(cat "$REPORT_FIN")
#EOF
#fi

# Finally, clean the workdir.
#cd /
#rm -rf "$WORK_DIR"
