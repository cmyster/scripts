TMP=/tmp/tmp_record

arecord -c 1 -D plughw:2,0 -d "$1" -f S32_LE -r 48000 -V mono -- "$TMP" && aplay -- "$TMP"

