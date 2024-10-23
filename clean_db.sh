#!/usr/bin/env bash
#
# This script will drop any schema in a DB except the ones in IGNORE.
# To add a schema to this list,  add '\|some_schema' to the end of it.
#

HOST = 127.0.0.1
USER = root
PASS = rootroot
EXEC = $(which mysql) # to bypass aliases

IGNORE = "mysql\|test\|performance_schema\|information_schema"

DBS = ( $($EXEC -h $HOST -u $USER -p$PASS -N -e "SHOW DATABASES;" \
            | grep -vsw "$IGNORE") )

for DB in ${DBS[@]}                                                   
do                                                                         
    echo "Removing $DB"
        $EXEC -h $HOST -u $USER -p$PASS -N -e "DROP DATABASE $DB;"
done
