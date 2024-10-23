#!/bin/bash

if [ $# -ne 2 ]
then
    printf "Usage : $0 <package path> <source path>\n"
    exit 1
fi

# if [ `whoami` != "root" ]
# then
#	printf "\nPlease run this script as root\n"
#    exit 1
# fi

EXE=$0
PKG=$1
PKG_TAR=${PKG/".gz"/}
echo $PKG_TAR
exit
SRC=$2

BKP_PATH=/home/amit/gdrive/slac/

7z x $PKG

# folder name:
foldername=`head -n 1 $pkgtar | awk -F/ '{print $1}'`

echo `pwd`
echo $foldername

tar xv $pkgtar
mv $src $foldername
rm $src

cd $foldername

executable=`ls -F | grep "*" | grep SlackBuild | sed 's/*//g'`
PRGNAM=`cat $executable | grep PRGNAM= | awk -F= '{print $2}'`
TAG=`cat $executable | grep TAG= | sed 's/[-_:$}{TAG=]//g'`

chmod +x $executable
$executable

echo 70

slackpack=`ls /tmp | grep $PRGNAM | grep $TAG`
mv $slackpack $backup
cd $backup

installpkg --menu --ask $slackpack

cd $origpath
