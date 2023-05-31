#!/bin/bash

CWD="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
TMP="/tmp/team_customer_cases"
MSG="The following bugs have an attached customer case, but the
qe_test_coverage flag is either not set, or set to ? (still in progress).
"
YEAR=$(( $(date +%Y) - 2 ))
FROM="$YEAR-$(date +%m-%d)"
Q1="https://bugzilla.redhat.com/buglist.cgi?bug_status=POST&bug_status=MODIFIED&bug_status=ON_QA&bug_status=VERIFIED&bug_status=CLOSED&chfield=%5BBug%20creation%5D&chfieldfrom=$FROM&chfieldto=Now&f1=qa_contact&f2=external_bugzilla.description&f5=OP&f6=flagtypes.name&f7=flagtypes.name&f8=CP&n6=1&n7=1&o1=equals&o2=equals&o6=equals&o7=equals&query_format=advanced&v1="
Q2="%40redhat.com&v2=Red%20Hat%20Customer%20Portal&v6=qe_test_coverage-&v7=qe_test_coverage%2B"

FULL="$TMP/full_report.txt"
FINAL="$TMP/final_report.txt"

rm -rf "$TMP" || exit 1
mkdir "$TMP" || exit 1

for list in $(find "$CWD/team_structure/" -mindepth 1)
do
    owner=$(head -n 1 "$list")
    tmp_report="${TMP}/tmp_${owner}"

    for user in $(cat "$list")
    do
        touch "${TMP}/${user}"
        Q="${Q1}${user}${Q2}"
        bugzilla query --field=limit=0 --from-url "${Q}" \
            --outputformat 'https://bugzilla.redhat.com/show_bug.cgi?id=%{id} - %{flags}' \
            | awk -F- '{
if ($2 ~ "qe_test_coverage")
print $1" - qe_test_coverage is still ?."
else
print $1" - qe_test_coverage is not set."
}' > "${TMP}/${user}"
        touch "$tmp_report"
        if [ "$(wc -l "${TMP}/${user}" | cut -d " " -f 1)" -gt 0 ] 2> /dev/null
        then
            echo -e "To: ${user}@redhat.com\nSubject: your customer bugs\n" \
                | (cat - && uuencode "${TMP}/${user}" report.txt) \
                | /usr/sbin/ssmtp "${user}@redhat.com"
            {
                echo "${user}'s bugs:"
                cat "${TMP}/${user}"
                echo "----------"
                echo ""
            } >> "$tmp_report"
        fi
    done
    touch "$FULL"
    if [ "$(wc -l "$tmp_report" | cut -d " " -f 1)" -gt 0 ] 2> /dev/null
    then
        cat "$tmp_report" >> "$FULL"
        report="${TMP}/${owner}"
        {
            echo "$MSG"
            cat "$tmp_report"
        } > "$report"
        echo -e "To: ${owner}@redhat.com\nSubject: team customer bugs\n" \
            | (cat - && uuencode "$report" report.txt) \
            | /usr/sbin/ssmtp "${owner}@redhat.com"
    fi
done

if [ "$(wc -l "$FULL" | cut -d " " -f 1)" -gt 0 ] 2> /dev/null
then
    echo "All bugs below are in this BZ link:" > "$FINAL"
    grep bugzilla "$FULL" \
        | cut -d " " -f 1 | cut -d "=" -f 2 \
        | tr "\n" " " | tr " " "," \
        | awk '{print "https://bugzilla.redhat.com/buglist.cgi?quicksearch="$0}' >> "$FINAL"
    echo ""

    cat "$FULL" >> "$FINAL"

    echo -e "To: achernet@redhat.com\nSubject: customer bugs - all teams\n" \
        | (cat - && uuencode "$FINAL" full_report.txt) \
        | /usr/sbin/ssmtp "achernet@redhat.com"
fi
