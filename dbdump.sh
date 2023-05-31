#!/bin/bash

# MySQL server information:
HOST=192.168.1.3
USER=root
PASS=rootroot

# files in use
OUT_FILE=dump-`date +%d%m%Y_%H%M%S`.sql

# Getting a list of databases
# DATABASES=$(echo `mysql -h $HOST -u $USER -p$PASS -e "show databases;" | awk '{print $1}' | grep -v "Database\|mysql\|information_schema\|performance_schema\|test"`)
DATABASES=testlink

# calling the command
echo "Dumping, this may take time..."

mysqldump \
-h $HOST \
-u $USER \
-p$PASS \
--order-by-primary \
--hex-blob \
--extended-insert \
--databases $DATABASES | sed 's/),(/),\n(/g' | sed 's/VALUES\ (/VALUES\ \n(/g' > $OUT_FILE

#unix2dos $OUT_FILE

echo Done
