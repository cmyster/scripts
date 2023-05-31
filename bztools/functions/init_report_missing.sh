#!/bin/bash

init_report_missing ()
{
   cp "$CWD/htmlstart" "$REPORT"

   if [ -z "${CARES##*1*}" ]
   then
       echo '<td style="text-align: center; width: 80px;"><strong>Triaged</strong></td>' >> "$REPORT"
   fi

   if [ -z "${CARES##*2*}" ]
   then
       echo '<td style="text-align: center; width: 80px;"><strong>Severity</strong></td>' >> "$REPORT"
   fi

   if [ -z "${CARES##*3*}" ]
   then
       echo '<td style="text-align: center; width: 80px;"><strong>Priority</strong></td>' >> "$REPORT"
   fi

   if [ -z "${CARES##*4*}" ]
   then
       echo '<td style="text-align: center; width: 80px;"><strong>Target</strong><br /><strong>Release</strong></td>' >> "$REPORT"
   fi

   echo '</tr>' >> "$REPORT"
}

