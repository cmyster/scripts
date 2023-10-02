#!/bin/bash

# This script goes over installed packages in a Gentoo installation and will
# use ebuild prepare command for each one to check if there is a missing
# kernel configuraion.
# Since packages will look for .config in /usr/src/linux, it needs a working
# kernel to work.

# Steps:
# 1. Get a list of installed packages using qlist -I.
# 2. For each package, get the exact installed atom,
#    this is needed to get the exact ebuild file.
# 3. For each ebuild file, see if it is looking for a kernel configuration.
# 4. If it does, run ebuild prepare command and log the output.

# Starting timer
SECONDS=0

# ebuild uses /var/tmp/portage and /var/cache/distfiles, so it needs to run as root.
if [ "$EUID" -ne 0 ]
    then printf "%s\n" "This script needs to be run as root."
    exit
fi

# Variables
REP_DIR="/var/db/repos"
WORK_DIR="/tmp/check_kernel_config"
LOG_FILE="/var/log/ebuild_prepare_log"
rm -rf $LOG_FILE
printf "===[ Start time: %s ]===\n" "$(date)" &> $LOG_FILE

# Create working directory
if [ ! -d $WORK_DIR ]; then
    mkdir -p $WORK_DIR
fi

# Get a list of installed packages
qlist -Iv > $WORK_DIR/installed_verbose
sed -i '/^$/d' $WORK_DIR/installed_verbose
PACKS=$(wc -l < $WORK_DIR/installed_verbose)
printf "There are %s packages to go over.\n" "$PACKS"

# All ebuilds are in the repos folder, might as well cd to it.
cd "$REP_DIR" || exit

# To save time later, lets get all the ebuild files now.
find . -type f -name "*.ebuild" > $WORK_DIR/all_ebuilds

# For each line in installed_verbose.txt, get the exact ebuild file.
printf "\n" > $WORK_DIR/test_ebuilds
INDEX=1
while read -r line
do
    CATEGORY=${line%%\/*}
    PACKAGE=$(printf "%s" "${line#*\/}" | rev | cut -d "-" -f 2- | rev)
    VERSION=$(printf "%s" "${line#*\/}" | rev | cut -d "-" -f 1 | rev)
    EBUILD=$(/usr/bin/grep -E "$CATEGORY.*/$PACKAGE.*$VERSION" "$WORK_DIR/all_ebuilds")
    printf "\r                                                                                                                                                                \r"
    printf "[%s out of %s] - ${CATEGORY}/${PACKAGE}" "$INDEX" "$PACKS"
    # Only write if the variable is not empty.
    if [ -n "$EBUILD" ]
    then
        printf "%s\n" "$EBUILD" &>> $WORK_DIR/test_ebuilds
    fi
    INDEX=$((INDEX+1))
done < $WORK_DIR/installed_verbose
printf "\n"
sed -i '/^$/d' $WORK_DIR/test_ebuilds

# Testing if there is a kernel configuration check in each ebuild.
printf "\n" > $WORK_DIR/found_ebuilds
while read -r test_ebuild
do
    if grep -q "CONFIG_CHECK" "$test_ebuild"
    then
        printf "%s\n" "$test_ebuild" &>> $WORK_DIR/found_ebuilds
    fi
done < $WORK_DIR/test_ebuilds

# 'sort', 'uniq' and 'sed' on the list to prevent duplicates and empty lines.
sort $WORK_DIR/found_ebuilds | uniq | sed '/^$/d' > $WORK_DIR/ebuilds
EBUILDS=$(wc -l < $WORK_DIR/ebuilds)
printf "There are %s ebuilds to go over.\n" "$EBUILDS"

# For each ebuild, run ebuild prepare command and add that to the log file.
INDEX=1
while read -r ebuild
do
    printf "\r                                                                                                                                                                \r"
    printf "[%s out of %s] - %s" "$INDEX" "$EBUILDS" "$ebuild"
    ebuild "$ebuild" clean prepare &>> $LOG_FILE
    INDEX=$((INDEX+1))
done < $WORK_DIR/ebuilds
printf "\n"

#Calculate runtime
MINUTES=$((SECONDS / 60))
SECONDS=$((SECONDS % 60))
if [ "$SECONDS" -lt 10 ]
then
    SECONDS="0$SECONDS"
fi

printf "Done in %s:%s.\nLog file is at: %s\n" "$MINUTES" "$SECONDS" "$LOG_FILE"
printf "You can use less and search for \"Checking for suitable kernel configuration options\"\nto see if there are any missing kernel configuration options.\n"

# Cleanup
rm -rf $WORK_DIR
