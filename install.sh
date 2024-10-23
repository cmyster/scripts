#!/bin/bash
#
# main installing script
#

set -x 

if [ $# -ne 1 ]
then
	echo "usage: $0 <path to version.7z>"
	exit 1

fi

if [ ! -f $1 ]
then
	echo "the file $1 was not found"
	exit 1
fi

export VER_PATH=$1
export VER=$(echo $VER_PATH | awk -F/ '{print $NF}' | sed 's/.7z//g')
export VER_FOLDER=/cygdrive/c/CommuniTake/Versions
export VER_FOLDER_WIN="C:\CommuniTake\Versions"
export UPDATER=/cygdrive/c/CommuniTake/Utils/tomcat.update-ct-build-version.cmd

echo "copying $VER.7z to $VER_FOLDER"
mv $VER_PATH $VER_FOLDER &> /dev/null
cd $VER_FOLDER &> /dev/null

echo "extracting $VER.7z"
7z x $VER.7z < <(yes Y) &> /dev/null
rm -rf $VER.7z

if [ $? -ne 0 ]
then
	echo "7z reported an error with $VER.7z. Please verify the file."
	exit 1
fi

$UPDATER $VER_FOLDER_WIN/$VER

