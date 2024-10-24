#!/bin/bash
set -x

XML_URL="https://www.bing.com/HPImageArchive.aspx?format=xml&n=1&mkt=en-US"
BASE_URL="https://www.bing.com"
IMG="$(curl -s "$XML_URL" | tr "<" "\n>" | grep urlBase | grep id | cut -d ">" -f 2)_1920x1080"
DIR="$HOME/Pictures/pic_of_day/"
cd "$DIR" || exit 1
curl -s "${BASE_URL}${IMG}.jpg" -o unprocessed.jpg &> /dev/null
$HOME/git/upscayl-ncnn/build/upscayl-bin -i "${DIR}/unprocessed.jpg" -o "${DIR}/processed.png" -m /usr/share/realesrgan-ncnn-vulkan/models
mv "processed.png" "pic_of_day.png"
rm -rf *.jpg
