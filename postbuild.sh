#!/bin/bash

BASE_DIR=`dirname $0`
TAR=`which tar`

cd $BASE_DIR
FOLDER=Version.`date "+%Y-%m-%d"`.`cat build.properties | cut -d '=' -f 2 | tr -d ' '`
#echo $FOLDER

$TAR -zcf $FOLDER.tgz $FOLDER



