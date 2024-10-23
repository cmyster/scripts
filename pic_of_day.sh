#!/bin/bash
set -x

XML_URL="https://www.bing.com/HPImageArchive.aspx?format=xml&n=1"
BASE_URL="https://h2.gifposter.com/bingImages"
IMG="$(curl -s "$XML_URL" | tr "<" "\n" | grep jpg | cut -d "." -f 2 | cut -d "_" -f 1,3)"
DIR="$HOME/Pictures/pic_of_day/"
cd "$DIR" || exit 1
echo "${BASE_URL}/${IMG}.jpg"
wget "${BASE_URL}/${IMG}.jpg"
$HOME/git/upscayl-ncnn/build/upscayl-bin -i "${DIR}/${IMG}.jpg" -o "${DIR}/${IMG}.png" -m /usr/share/realesrgan-ncnn-vulkan/models
mv "${IMG}.png" "pic_of_day.png"
rm -rf wget-log "${IMG}.jpg"
