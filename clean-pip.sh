#!/bin/bash

if [[ "$(whoami)" != "root" ]]
then
    echo please only run $0 as root
fi

if [ -z "$1" ]
then
    ROOT_PATH="."
else
    ROOT_PATH="$1"
fi

TMP_LIST=/tmp/piplist

find $ROOT_PATH -type f -name "*requirements.txt" | \
    xargs cat | \
    tr ">" " " | \
    tr "=" " " | \
    cut -d " " -f 1 | \
    sort | uniq | grep -v "#" > $TMP_LIST

for pip_pkg in $(cat $TMP_LIST)
do
    pip uninstall $pip_pkg -y
done
