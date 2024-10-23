#!/bin/bash

trap 'echo -ne "\nInterrupted!\n"; exit' INT

ECHO="/usr/bin/echo -ne"
LOGGER () {
    $ECHO "$1"
}

NORMAL=$(tput sgr0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)

# normalizing the output color, and setting colors for status
printf "%40s\n" "${NORMAL}Starting the uploader script"

SUCCESS () {
    printf "%$((43-$1))s\n" "${GREEN}[  OK  ]${NORMAL}"
}

FAIL () {
    printf "%$((43-$1))s\n" "${RED}[ FAIL ]${NORMAL}"
}

HOST="localhost"
USER="root"
PASS="rootroot"

DIA_LOG=dialog.results
rm -rf $DIA_LOG

# Store data to $VALUES variable
dialog --backtitle "SQL Server Uploader" \
       --title "Sever Details" \
       --mixedform "Enter server credentials" 10 40 0 \
                   "Host/IP:   " 1 1 "$HOST" 1 14 20 0 0 \
                   "Username:  " 2 1 "$USER" 2 14 20 0 0 \
                   "Password:  " 3 1 "$PASS" 3 14 20 0 0 2> $DIA_LOG

if [ $? != 0 ]
then
    exit 2
fi

export HOST=$(head -n 1 $DIA_LOG)
export USER=$(head -n 2 $DIA_LOG | tail -1)
export PASS=$(head -n 3 $DIA_LOG | tail -1)

rm -rf $DIA_LOG

sql_folder=/home/cmyster/FIX/db
MYSQL=mysql

file_array=( $(find $sql_folder | grep "\.sql" | grep -v "update\|event") )

FINAL=true
FAILS=""
for s in "${file_array[@]}"
do
    schema=$(echo $s | awk -F/ '{print $NF}' | sed 's/.sql//g')

	LOGGER "Uploading: $schema"
	$MYSQL -h $HOST -u $USER -p$PASS < $s &> /dev/null

	if [ $? -ne 0 ]
	then
        FAIL ${#schema}
        FAILS+="    $schema\n"
        export FINAL=false
	else
		SUCCESS ${#schema}
	fi
done

ERR_MSG="The following schemas have failed to be uploaded.\n
Please try to upload them manually and see what errors are being returned.\n"

if [ $FINAL ]
then
    dialog --backtitle "SQL Server Uploader" \
           --title "Failed uploads" \
           --msgbox "$ERR_MSG\n$FAILS" 15 55
fi

exit

