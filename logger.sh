#bin/bash
LOG_FILE=~/logs/$0.log
rm -rf $LOG_FILE
ECHO="/usr/bin/echo -ne"
L_LVL=( INFO WARN ERRO CRIT )
LOGGER () {
    $ECHO "[$(date +%d/%m/%y_%T]) [$1] [$2]\n" >> $LOG_FILE
}

LOGGER "${L_LVL[0]}" "1st thing to be logged"
LOGGER "${L_LVL[1]}" "2nd thing to be logged"
LOGGER "${L_LVL[2]}" "3rd thing to be logged"
LOGGER "${L_LVL[3]}" "4th thing to be logged"

cat $LOG_FILE
