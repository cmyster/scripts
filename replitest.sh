#!/bin/bash
CURRENT=`mysql -u root -prootroot -e "select count(START_TIME) from chief_logging.csr_sessions;" | grep -v "count\||"`
while (true)
do
        TEMP=`mysql -u root -prootroot -e "select count(START_TIME) from chief_logging.csr_sessions;" | grep -v "count\||"` > /dev/null
        if (( $TEMP != $CURRENT ))
        then
                echo "Number of chief_logging.csr_sessions has changed!"
                echo "Former size = $CURRENT"
                echo "   New size = $TEMP"

                CURRENT=$TEMP
        fi

        sleep 5
done