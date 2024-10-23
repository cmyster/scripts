#!/bin/bash

CWD=$(pwd)
TMP=/tmp
PKG_NAME="$1"
PKG_DIR=$TMP/"$PKG_NAME"-package
PKG_DIST=$PKG_DIR/usr

pip list 2> /dev/null | grep -i "$PKG_NAME " &> /dev/null
if [ $? -eq 0 ]
then
    echo "Package already installed."
    exit 0
fi

rm -rf $PKG_DIR $PIP_LOG $TMP/"$PKG_NAME"-noarch_cmyster.txz
pip search $PKG_NAME | grep "^$PKG_NAME " &> /dev/null
if [ $? -ne 0 ]
then
    echo "Package not found."
    exit 0
fi

VERSION=$(pip search $PKG_NAME | grep "^$PKG_NAME " | cut -d " " -f 2 | tr -d "()")

pip install --install-option="--prefix=$PKG_DIST" "$PKG_NAME"

cd $PKG_DIR
makepkg -l y -c n $TMP/$PKG_NAME-$VERSION-noarch_cmyster.txz
