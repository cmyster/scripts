#!/bin/bash

sql_folder=/cygdrive/c/CommuniTake/CurrentVersion/sql
MYSQL=/home/ct/mysql.exe
db_host=10.0.0.141
db_user=root
db_pass=rootroot

max_string_length=0

schema_array=( $(find $sql_folder | grep "\.sql" | grep -v "update\|events") )

for file in ${file_array[@]}
do
    if [ ${#file} -gt $max_string_length ]
    then
        export max_schema_length=${#file}
    fi
done

echo $max_schema_length

for i in "${file_array[@]}"
do
    schema=$(echo $i | awk -F/ '{print $NF}' | sed 's/.sql//g')

    spaces=""
    space_num=$(( $max_schema_length - ${#schema} ))
    echo $space_num
    for i in 1..$space_num
    do
        spaces="$spaces "
    done

    echo "space $space space"
    exit 0

    echo -n "Now uploading: $schema" 
    sleep 1
    # mysql -h $db_host -u $db_user -p$db_pass < $i
    retval=$?
    if [ $retval != 0 ]
    then
        echo -ne "$spaces[ FAIL ]"
        exit 1
    else
        echo -ne "$spaces[  OK  ]"
    fi
    echo ""
done
exit 0
