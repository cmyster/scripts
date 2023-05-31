#!/bin/bash

find -type d | grep \.\/ | xargs rm -rf
tar xf $1
FOLDER=$(find -type d | grep \.\/)
mv $2 $FOLDER
chown root:root -R $FOLDER
cd $FOLDER
PRGNAM=$(grep ^PRGNAM $(find *.?lack?uild) | cut -d = -f 2)
bash $(find *.?lack?uild)
cd ..
installpkg /tmp/$PRGNAM*
DEST=/home/augol/slack
mv /tmp/$PRGNAM* $DEST
rm -rf $1 $2 $FOLDER
