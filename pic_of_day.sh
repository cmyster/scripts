#!/bin/bash
set -x

XML_URL="https://www.bing.com/HPImageArchive.aspx?format=xml&n=1"
BASE_URL="https://h2.gifposter.com/bingImages"
IMG="$(curl -s "$XML_URL" | tr "<" "\n" | grep jpg | cut -d "." -f 2 | cut -d "_" -f 1,3).jpg"
DIR="$HOME/Pictures/pic_of_day/"
cd "$DIR" || exit 1
wget "${BASE_URL}/${IMG}"
mv "${IMG}" "pic_of_day.jpeg"
