#!/bin/bash
#
# This script will download bing's image of the day, get the average color
# from the leftmost or rightmost side of it (depends on conky's configuration)
# and reverse it and set that as the foreground color. This way you get the
# latest image of the day plus conky's text is legible when over it.

PIC_DIR="$HOME/Pictures"
PIC_EXT="jpeg"
PIC_NAME="pic_of_day.${PIC_EXT}"
PIC="$PIC_DIR/pic_of_day/$PIC_NAME"
TMP=~/tmp/conker
TIME="$(date +%H_%M_%S)"
LOG_DIR=~/logs
LOG_FILE="$LOG_DIR/conker_$TIME"
TEMP_PIC=$TMP/tmp_pic
RC=~/.conkyrc

printf "%s" "$TIME" >"$LOG_FILE"

logger() {
	printf "%s - %s" "$(date +%T)" "$1" >>"$LOG_FILE"
}

clean() {
	rm -rf "${TMP}"
}

exists() {
	if ! command -v "$1" &>/dev/null; then
		logger "$1 not found, you need to install it first."
		exit 1
	fi
}

stop_conky() {
	killall conky &>/dev/null
}

start_conky() {
	conky &>/dev/null &
}

restart_conky() {
	stop_conky
	start_conky
}

clean

if [ ! -d $LOG_DIR ]; then
	mkdir -p $LOG_DIR
fi

if [ ! -d $TMP ]; then
	mkdir -p $TMP
fi

# These are the tools the script uses. Don't continue if not installed.
for tool in "convert" "xrandr"; do
	exists $tool
done

# Getting Monitor's Width and Height
SCREEN_X=$(xrandr | grep '\*' | awk '{print $1}' | cut -d 'x' -f 1)
SCREEN_Y=$(xrandr | grep '\*' | awk '{print $1}' | cut -d 'x' -f 2)
logger "Screen's resolution is $SCREEN_X x $SCREEN_Y"

# Getting conky's width. If empty, set to 500.
if grep minimum_width $RC &>/dev/null; then
	CONKY_X=$(grep minimum_width $RC | awk '{print $NF}' | tr -d ",")
else
	CONKY_X=500
fi
logger "Conky minimal width is $CONKY_X."

# Downloading the image of the day.
logger "Downloading image."
rm -rf /home/augol/.bing-wallpapers/*
/home/augol/node_modules/bing-daily-wallpaper/bin/bing-daily-wallpaper &>"$LOG_FILE"
TEMP_PIC_PATH="$(find /home/augol/.bing-wallpapers/ -mindepth 1)"
# No need to continue if the online image is the same as the one being used.
MD5="$(md5sum "$PIC" | cut -d " " -f 1)"
UP_MD5="$(md5sum "$TEMP_PIC_PATH" | cut -d " " -f 1)"

if [[ "$MD5" == "$UP_MD5" ]]; then
	logger "Current picture of the day is the latest one."
	exit 0
fi

# Add a border surrounding the image if the sownloaded image is smaller
# than the screen resolution.

DOWN_X_RES="$(file "$TEMP_PIC_PATH" | sed 's/, /\n/g' | grep "^[0-9].*x[0-9]" | cut -d "x" -f 1)"
DOWN_Y_RES="$(file "$TEMP_PIC_PATH" | sed 's/, /\n/g' | grep "^[0-9].*x[0-9]" | cut -d "x" -f 2)"

if [ "$DOWN_X_RES" -lt "$SCREEN_X" ] || [ "$DOWN_Y_RES" -lt "$SCREEN_Y" ]; then
	convert "$TEMP_PIC_PATH" -resize "${SCREEN_X}x${SCREEN_Y}" "$TEMP_PIC_PATH"
fi

# Testing conky's allignment for right or left side.
#GRAVITY=West
#if grep alignment ~/.conkyrc | grep -q right; then
#	GRAVITY=East
#fi
# Get the average color of the side of the image.
# First break the image to left and right parts depending on the conky's width.
# TODO:
# Needs to mirror the behaviour if conky is set to the left side.

# Create a frame and center the image to the $CENTER side.
# convert "$TEMP_PIC_PATH" -size "${SCREEN_X}x${SCREEN_Y}" xc:"$AVG_COLOR" +swap -gravity "$GRAVITY" -composite "$TEMP_PIC_PATH"
convert "$TEMP_PIC_PATH" -crop "$((SCREEN_X - CONKY_X))x$SCREEN_Y" "${TEMP_PIC}.${PIC_EXT}"
convert "${TEMP_PIC}-1.${PIC_EXT}" -resize 1x1 -channel RGB -negate "${TMP}/n1x1.txt"
NAVG_COLOR="$(tail -n 1 ${TMP}/n1x1.txt | awk '{print $3}')"

stop_conky
cp "$TEMP_PIC_PATH" "$PIC"
sed -i "s/default_color = .*/default_color = '${NAVG_COLOR}',/g" $RC
restart_conky
clean
