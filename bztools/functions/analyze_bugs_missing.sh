#!/bin/bash

analyze_bugs_missing ()
{
    while IFS= read -r bug
    do
        # issue is an indicator. Only the first time a problem is found,
        # the bugs summary and URL will be written.
        issue=0

        # Setting bug attributes by order:
        export summary=""    # The bug's summary.
        export bug_html=""   # Bug ID will be shown as a link to BZ.

        # The following will be a checkmark or a message in the report:
        export triaged=""    # Checks if has the Triaged keyword.
        export severity=""   # Checks if severity is not unspecified.
        export priority=""   # Checks if priority is not unspecified.
        export target=""     # Checks if a target release exists.

        # Assigning summary and bug_html first.
        summary="$(grep "ATTRIBUTE.summary" "$bug" | cut -d ":" -f 2- | sed 's/^ //')"
        bz_id=$(echo "$bug" | cut -d "." -f 2 | tr -d "/")
        bug_url="https://bugzilla.redhat.com/show_bug.cgi?id=${bz_id}"
        bug_html="<a href=\"${bug_url}\">${bz_id}</a>"

        if [ -z "${CARES##*1*}" ]
        then
            if ! grep "ATTRIBUTE.keywords" "$bug" | grep -q "Triaged"
            then
                export triaged="untriaged"
                issue=1
            else
                export triaged="&#10003;"
            fi
        else
            export triaged="N/A"
        fi


        if [ -z "${CARES##*2*}" ]
        then
            if grep "ATTRIBUTE.severity" "$bug" | grep -q "unspecified"
            then
                export severity="missing"
                issue=1
            else
                export severity="&#10003;"
            fi
        else
            export severity="N/A"
        fi

        if [ -z "${CARES##*3*}" ]
        then
            if grep "ATTRIBUTE.priority" "$bug" | grep -q "unspecified"
            then
                export priority="missing"
                issue=1
            else
                export priority="&#10003;"
            fi
        else
            export priority="N/A"
        fi

        if [ -z "${CARES##*4*}" ]
        then
            if ! grep "ATTRIBUTE.target_release" "$bug" | grep -q -o "[0-9]"
            then
                export target="missing"
                issue=1
            else
                export target="&#10003;"
            fi
        else
            export target="N/A"
        fi

        if [ $issue -eq 1 ]
        then
            {
                echo "<tr>"
                echo "<td>${summary}</td>"
                echo "${TDC}${bug_html}</td>"
                echo "${TDC}${triaged}</td>"
                echo "${TDC}${severity}</td>"
                echo "${TDC}${priority}</td>"
                echo "${TDC}${target}</td>"
                echo "</tr>"
            } >> "$REPORT"

            export SEND_MAIL=true
        fi
    done < <(find . -maxdepth 1 -mindepth 1 -name "*.raw")
}
