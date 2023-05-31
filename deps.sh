#!/bin/bash
APP=$(which $1)
for LIB in $(ldd $APP | awk '{print $1}')
do
    /usr/sbin/slackpkg file-search $LIB | grep uninstal
done
