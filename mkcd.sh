#!/bin/bash

# Creates a Slackware ISO based on my prefs.

LIST="/home/augol/gdrive/config/installed"
WORK_DIR="/tmp/mk_cd"
SRC_DIR="/home/ftp/pub/Linux/Slackware/slackware64-current"
TGT_DIR="/home/ftp/pub/Linux/Slackware/slackware64-current-iso"
CP_LIST=cp_list

# File called installed is supplied. If thats unreadable, don't continue.
if [ ! -r $LIST ]
then
    echo "Installed file not found!"
    exit 1
fi

# If the workdir is there, clean and re-create, otherwise only create.
if [ -d $WORK_DIR ]
then
    rm -rf $WORK_DIR
    mkdir -p $WORK_DIR
else
    mkdir -p $WORK_DIR
fi

cd $SRC_DIR

# Copy none packages.
echo "Copying none packages."
cp -ar $(find . -maxdepth 1 -mindepth 1 | grep -v "testing\|extra\|source\|slackware64") $WORK_DIR

# Create a list of packages to be copied.
for package_name in $(cat /home/augol/gdrive/config/installed)
do
    find . -name "$package_name*"
done | grep txz$ | grep -v testing | sort | uniq > $CP_LIST

# Readding specific packages whose names do not follow the majority.
add_extra()
{
    find . -name "${1}*" \
        | grep -v "testing\|extra\|source" \
        | grep txz$ >> $CP_LIST
}

for extra in "freetype" "iputils" "cdparanoia"
do
    add_extra "$extra"
done

exit

# Copying packages.
echo "Copying packages."
for package_file in $(cat $CP_LIST)
do
    cp --parents $package_file $WORK_DIR
done

rm -f $CP_LIST

cd $WORK_DIR

# Creating the ISO.
echo "Creating an image."
mkisofs -o slackware64-current-install.iso \
    -R -J -V "Slackware-current DVD" \
    -hide-rr-moved -hide-joliet-trans-tbl \
    -v -d -N -no-emul-boot -boot-load-size 32 -boot-info-table \
    -sort isolinux/iso.sort \
    -b isolinux/isolinux.bin \
    -c isolinux/isolinux.boot \
    -preparer "Slackware-current build for x86_64 by Amit Ugol <amit.ugol@gmail.com>" \
    -publisher "The Slackware Linux Project - http://www.slackware.com" \
    -A "Slackware-current DVD" \
    -eltorito-alt-boot -no-emul-boot -eltorito-platform 0xEF -eltorito-boot isolinux/efiboot.img \
    . &> $TGT_DIR/mkisofs.log

mv slackware64-current-install.iso $TGT_DIR
cd ..
rm -rf $WORK_DIR
