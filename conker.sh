#!/bin/bash

PIC_DIR="$HOME/Pictures"
PIC_NAME="pic_of_day.jpg"
PIC="$PIC_DIR/pic_of_day/$PIC_NAME"
TMP=~/tmp
TIME="$(date +%H_%M_%S)"
LOG_DIR=~/logs
LOG_FILE="$LOG_DIR/conker_$TIME"
TPIC=$TMP/cpic
CPIC=${TPIC}.jpg
RGB=$TMP/avg_pic_rgb
CRGB=$TMP/avg_pic_crgb
RC=~/.conkyrc
AVG=5
PIC_URL=$(lynx --dump https://apod.nasa.gov/apod/astropix.html | grep https | grep jpg | grep -v label | awk '{print $NF}')

if [ ! -d $LOG_DIR ]
then
    mkdir $LOG_DIR
fi

echo "$TIME" > "$LOG_FILE"

logger ()
{
    echo "$(date +%T) - $1" >> "$LOG_FILE"
}

clean ()
{
    rm -rf $RGB $CRGB ${TPIC}*
}

exists ()
{
    if ! command -v "$1" &> /dev/null
    then
         logger "$1 not found, you need to install it first."
         exit 1
    fi
}

stop_conky ()
{
    killall conky &> /dev/null
}

start_conky ()
{
    conky &> /dev/null &
}

restart_conky ()
{
    stop_conky
    start_conky
}

clean

# These are the tools the script uses. Don't continue if not installed.
for tool in "convert" "lynx" "curl" "xrandr"
do
    exists $tool
done

# Getting Monitor's Width and Height
MW=$(xrandr | grep './*+$' | awk '{print $1}' | cut -d 'x' -f 1)
MH=$(xrandr | grep './*+$' | awk '{print $1}' | cut -d 'x' -f 2)
logger "Monitor's resolution is $MW x $MH"

# Getting conky's width. If empty, set to 500.
if grep minimum_width $RC &> /dev/null
then
    CW=$(grep minimum_width $RC | awk '{print $NF}' | tr -d ",")
else
    CW=500
fi
logger "Conky minimal width is $CW."

# Downloading the image of the day.
logger "Using image path: $PIC_URL."
curl "$PIC_URL" -o $TMP/$PIC_NAME &>> "$LOG_FILE"

# No need to continue if the online image is the same as the one being used.
MD5="$(md5sum "$PIC" | cut -d " " -f 1)"
UP_MD5="$(md5sum $TMP/$PIC_NAME | cut -d " " -f 1)"

if [[ "$MD5" == "$UP_MD5" ]]
then
    logger "Current picture of the day is the latest one."
    exit 0
fi

mv $TMP/$PIC_NAME "$PIC"

# If the monitor's resolution is larger that the maximum image size (FHD),
# resize it.
# convert "$PIC" -resize "${MW}x${MH}" "$PIC"

# TODO:
# This needs to be valuated - is conkey running on left or right side.

set -x
# Conky is set to run on right side, so I need to calculate colors only for
# the right-most 600 or so pixels. This command will split the original image
# to 2 giving each a new filename ending with -0 and -1.
convert -crop "$(( MW - CW ))x$MH" "$PIC" "$CPIC"

# Before counting the most common colors it would be better to reduce color
# bits (less overall total number of distinct colors).
convert ${TPIC}-1.jpg -auto-level -depth 3 -format %c histogram:info:- \
  | sort -h | tail -n $AVG | tr "," " " | tr -d "()a-z" \
  | awk '{print int($6)"_"int($7)"_"int($8)}' > $RGB

# Get the RGB values of the cropped image and reverse them with 255-X.
while read -r val
do
    R=$(echo "$val" | cut -d "_" -f 1)
    G=$(echo "$val" | cut -d "_" -f 2)
    B=$(echo "$val" | cut -d "_" -f 3)
    echo "$(( 255 - R ))_$(( 255 - G ))_$(( 255 - B ))" >> $CRGB
done < $RGB

# Re-create the color map.
while read -r cval
do
    CR=$(( CR + $(echo "$cval" | cut -d "_" -f 1) ))
    CG=$(( CG + $(echo "$cval" | cut -d "_" -f 2) ))
    CB=$(( CB + $(echo "$cval" | cut -d "_" -f 3) ))
done < $CRGB
set +x
# If the sum of the average RGB is greater then 255*3/2, than it is a dark
# image (calculating from the reversed colors) and it will be brightened and
# vice versa.

CR=$(( CR / AVG))
CG=$(( CG / AVG))
CB=$(( CB / AVG))

if [ $(( CR + CG + CB )) -gt 382 ]
then
    if [ $(( CR + DELTA )) -lt 256 ]
    then
        CR=$(( CR + DELTA ))
    fi
    if [ $(( CG + DELTA )) -lt 256 ]
    then
        CR=$(( CG + DELTA ))
    fi
    if [ $(( CB + DELTA )) -lt 256 ]
    then
        CR=$(( CB + DELTA ))
    fi
else
    if [ $(( CR - DELTA )) -gt 0 ]
    then
        CR=$(( CR - DELTA ))
    fi
    if [ $(( CG - DELTA )) -gt 0 ]
    then
        CR=$(( CG - DELTA ))
    fi
    if [ $(( CB - DELTA )) -gt 0 ]
    then
        CR=$(( CB - DELTA ))
    fi
fi

# Using the final $AVG values means that I need to divide by $AVG to get an
# average color from those. This will set the foreground color for conky.

FR=$(printf '%x' $CR)
FG=$(printf '%x' $CG)
FB=$(printf '%x' $CB)

# Keeping the color-code scheme, if length is only 1, add a leading 0, i.e
# 'a' becomes '0a'.
if [[ ${#FR} == 1 ]]
then
    FR="0$FR"
fi
if [[ ${#FG} == 1 ]]
then
    FG="0$FG"
fi
if [[ ${#FB} == 1 ]]
then
    FB="0$FB"
fi

stop_conky

sed -i "s/default_color = .*/default_color = '$FR$FG$FB',/g" $RC

# If we're on XFCE, the change is immediate and there is no reason to run
# anything.
# For KDE there there is some qdbus magic that I am delegating to this other
# script thats beeing maintained at:
# https://github.com/pashazz/ksetwallpaper/blob/master/ksetwallpaper.py

if [[ "$XDG_CURRENT_DESKTOP" == "KDE" ]]
then
    /home/augol/scripts/ksetwallpaper.py -f \
        /home/augol/Pictures/pic_of_day/pic_of_day.jpg
fi

restart_conky

clean
