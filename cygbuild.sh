#!/bin/bash
#
# CygBuild, an optimistic attempt to make sometihng like Slackware's
# SlackBuilds for cygwin.
# Thanks to Patrick J. Volkerding and the Salckware team for this perfect way
# to build things, and thanks SlackBuilds memebers.
# Whithout stealing from you all, this could never have happened.
#
# things that are needed here:
# The system needs to be able to build stuff successfully.
# There is no dependency resolution here, please make sure everything's ready.
# Please have util-linux installed.
#
# This script needs an argument for the package's source file
# Examples:
# libsomelib-1.2.3.tar.gz 
# appsomeapp_2-12.34.tgz 

USAGE="usage: $0 <package name>"

if [ $# != 1 ]
then
    echo $USAGE
    exit 1
fi

export ARCH=$( uname -m )
export OS=$( uname -o )
PKGNAM=$(echo $1 | rev | cut -f 3- -d . | cut -f 2 -d - | rev)
VERSION=$(echo $1 | rev | cut -f 3- -d . | cut -f 1 -d - | rev)
BUILD=${BUILD:-1}
NUMJOBS=${NUMJOBS:-" -j7 "}
CWD=$(pwd)
TMP=/tmp
PKG=$TMP/$PKGNAM-$VERSION_$ARCH-$BUILD

if [ "$ARCH" = "i486" ]
then
    CYGCFLAGS="-O2 -march=i486 -mtune=i686"
    LIBDIRSUFFIX=""
elif [ "$ARCH" = "s390" ]
then
    CYGCFLAGS="-O2"
    LIBDIRSUFFIX=""
elif [ "$ARCH" = "x86_64" ]
then
    CYGCFLAGS="-O2 -fPIC"
    LIBDIRSUFFIX="64"
else
    CYGCFLAGS="-O2"
    LIBDIRSUFFIX=""
fi

rm -rf $PKG
mkdir -p $PKG
cd $TMP
rm -rf $PKGNAM-$VERSION
tar xvf $CWD/$PKGNAM-$VERSION*.* || exit 1
cd $PKGNAM-$VERSION
find . \
    \( -perm 777 -o -perm 775 -o -perm 711 -o -perm 555 -o -perm 511 \) \
    -exec chmod 755 {} \; -o \
    \( -perm 666 -o -perm 664 -o -perm 600 -o -perm 444 -o -perm 440 -o -perm 400 \) \
    -exec chmod 644 {} \;

CFLAGS="$CYGCFLAGS" \
CXXFLAGS="$CYGCFLAGS" \
./configure \
    --prefix=/usr \
    --libdir=/usr/lib${LIBDIRSUFFIX} \
    --infodir=/usr/info \
    # the -linux is a little white lie to bypass some nasty make files
    --build=$ARCH-$OS-linux \
    --host=$ARCH-$OS-linux

make $NUMJOBS || make || exit 1
make install DESTDIR=$PKG || exit 1

find $PKG | xargs file | grep -e "executable" -e "shared object" | grep ELF \
    | cut -f 1 -d : | xargs strip --strip-unneeded 2> /dev/null

gzip -9 $PKG/usr/info/*.info
rm -rf $PKG/usr/info/dir

mkdir -p $PKG/usr/doc/$PKGNAM-$VERSION
cp -a \
    AUTHORS COPYING* INSTALL NEWS README* THANKS TODO \
    $PKG/usr/doc/$PKGNAM-$VERSION

find $PKG > $PKG/usr/doc/$PKGNAM-$VERSION.files
