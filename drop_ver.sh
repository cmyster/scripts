#!/bin/bash

set -e

# Saving arguments for later
ARGS=("$@")

# Setting usage message
USAGE="$0 - A simple bash script to create the latest Dropbox slackbuild.\n
Options - [path to dropbox.info] [-h||--help] [-y||--yes] [-n||--no]\n
\thelp\t- Print this message and exit.\n
\tyes\t- If set, package will be created, otherwise there is a prompt.\n
\tno\t- No matter what, always stop after version is prompted."

# Setting prompt message
PROMPT="Do you want to continue with the SlackBuild creation? (Y/N)"

# I don't want to go over millions of arguments
if [ ${#ARGS[@]} -gt 5 ] || [ ${#ARGS[@]} -lt 1 ]
then
    echo -e "$USAGE"
    exit 1
fi

# Setting flags
HELP=false
YES=false
NO=false
for ARG in "${ARGS[@]}"
do
    if [[ $ARG == "-h" || $ARG == "--help" ]]
    then
        export HELP=true
    fi
    if [[ $ARG == "-y" || $ARG == "--yes" ]]
    then
        export YES=true
    fi
    if [[ $ARG == "-n" || $ARG == "--no" ]]
    then
        export NO=true
    fi
done

# If HELP, lets echo and stop here.
if $HELP
then
    echo -e "$USAGE"
    exit 0
fi

# Creating a work space
TMP_DIR=/tmp/drop-ver
rm -rf $TMP_DIR
mkdir $TMP_DIR
LANDING="$TMP_DIR/dropbox-landing"
LATEST_PAGE="$TMP_DIR/latest_version-page"

# This is the URL with the most up-to-date release notes
URL="https://www.dropboxforum.com/t5/Desktop-client-builds/bd-p/101003016"

# Sourcing the info file
if [ -r "$1" ]
then
    echo "Using $1 as source"
    source "$1"
else
    echo -e "$USAGE"
fi

# Some sanity
if [ ! "$VERSION" ] || [ ! "$DOWNLOAD" ]
then
    echo "Invalid info file"
    exit 1
fi

# Checking for latest changes
echo "Testing for latest online version"
lynx --dump "$URL" > "$TMP_DIR/dropbox-landing"
STABLE_LINK_NUMBER=$(grep -A2 "Most recent builds" "$LANDING" | grep "Stable" | cut -d "]" -f 1 | cut -d "[" -f 2)
STABLE_LINK_URL=$(grep http "$LANDING" | grep " ${STABLE_LINK_NUMBER}. " | awk '{print $NF}')
lynx --dump "$STABLE_LINK_URL" > "$LATEST_PAGE"
ONLINE_VER=$(head -n 1 "$LATEST_PAGE" | awk '{print $4}')

echo "Got latest online version: $ONLINE_VER"

# Is the online version larger then the current one?
BIGGER=$(echo -ne "$ONLINE_VER\n$VERSION" | sort -V | tail -n 1)
if [ "$BIGGER" != "$VERSION" ]
then
    echo "Online version ($ONLINE_VER) is newer then current version ($VERSION)"
else
    echo "Current version in the slackbuild is the latest"
    if ! $YES
    then
        echo "$PROMPT"
        read -r input
        if ! [[ $input == "Y" || $input == "y" ]]
        then
            echo "Operation aborted by user"
            exit 0
        fi
    fi
fi

# If we set -n, just exit after the versions are shown.
if $NO
then
    exit 0
fi

# If we set -y continue, otherwise promt and decide later.
if ! $YES
then
    echo "$PROMPT"
    read -r input
    if ! [[ $input == "Y" || $input == "y" ]]
    then
        echo "Operation aborted by user"
        exit 0
    fi
fi

set -x
ARCH_32_LINK_NUM=$(grep "Linux" "$LATEST_PAGE" | grep "Installer" | grep -E -o ".[0-9].x86 " | cut -d "]" -f 1)
ARCH_32_LINK_URL=$(grep http "$LATEST_PAGE" | grep " ${ARCH_32_LINK_NUM}. " | awk '{print $NF}')
FILE_32=$(echo "$ARCH_32_LINK_URL" | rev | cut -d "/" -f 1 | rev)
ARCH_64_LINK_NUM=$(grep "Linux" "$LATEST_PAGE" | grep "Installer" | grep -E -o ".[0-9].x86_64" | cut -d "]" -f 1)
ARCH_64_LINK_URL=$(grep http "$LATEST_PAGE" | grep " ${ARCH_64_LINK_NUM}. " | awk '{print $NF}')
FILE_64=$(echo "$ARCH_64_LINK_URL" | rev | cut -d "/" -f 1 | rev)

# Copying stuff elsewhere so we won't overwrite the original slackbuild.
INF_PATH=$(realpath "$1" | xargs dirname)
cp -R "$INF_PATH"/* $TMP_DIR
cd "$TMP_DIR" || exit 1
sed -i 's/'$VERSION'/'$ONLINE_VER'/g' dropbox.info
sed -i 's/:-'$VERSION'/:-'$ONLINE_VER'/g' dropbox.SlackBuild

# Resource the info file again, now with the new version info.
source dropbox.info

# Getting the binaries
echo "Downloading packages."
wget -nc "$ARCH_32_LINK_URL"
wget -nc "$ARCH_64_LINK_URL"

# Getting the new md5s from the downloaded files and replacing them in
# the info file.
MD5_32=$(md5sum "$FILE_32" | cut -d " " -f 1)
MD5_64=$(md5sum "$FILE_64" | cut -d " " -f 1)

LOG_LINE=$(grep -nr "SlackBuild changelog" dropbox.SlackBuild | cut -d ":" -f 1)
ENTRY_LINE=$(( LOG_LINE + 1 ))

sed -i 's/'$MD5SUM'/'$MD5_32'/g' dropbox.info
sed -i 's/'$MD5SUM_x86_64'/'$MD5_64'/g' dropbox.info
sed -i "${ENTRY_LINE}i# $(date +%d/%b/%Y) * Updated to latest version $ONLINE_VER" dropbox.SlackBuild
echo "SlackBuild was updated to version $ONLINE_VER"

ENTRY_NUM=$(grep -nr "\#.*/20" dropbox.SlackBuild | wc -l)

if [ "$ENTRY_NUM" -gt 15 ]
then
    LAST_ENTRY=$(grep -nr "\#.*/20" dropbox.SlackBuild | tail -n 1 | cut -d ":" -f 1)
    ENTRY_END=$(grep -nr "###" dropbox.SlackBuild | tail -n -1 | cut -d ":" -f 1)
    ENTRY_END=$(( "$ENTRY_END" - 1 ))
    sed -i "${LAST_ENTRY},${ENTRY_END}d" dropbox.SlackBuild
fi

# Copying the new .info and .SlackBuild back to the original path and
# packaging the new slackbuild.
cp -a dropbox.info dropbox.SlackBuild "$INF_PATH"
cd "$INF_PATH" || exit 1
cd ..
rm -rf dropbox.tar.gz
tar cf dropbox.tar dropbox
gzip -9 dropbox.tar

# Summarizing it up in CLI, Notify and Zenity.
echo "$TMP_DIR contains the latest script and binary packages should you want to create a packge."
if command -v notify-send &> /dev/null
then
	notify-send "New Dropbox Version" "Dropbox version $ONLINE_VER is ready to be created in $TMP_DIR" &> /dev/null &
else
    echo "Can't find notify-send so not using that"
fi
if command -v zenity &> /dev/null
then
	zenity --info --title "New Dropbox Version" --text "There is a new Dropbox version $ONLINE_VER waiting to be created in $TMP_DIR" &> /dev/null &
else
    echo "Can't find zenity so not using that"
fi
