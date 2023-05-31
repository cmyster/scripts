#!/bin/bash
set -x
export QT_DEBUG_PLUGINS=1
export LIBGL_ALWAYS_INDIRECT=""
export DISPLAY=:0

eval "$(date +'today=%F now=%s')"
midnight=$(date -d "$today 0" +%s)
seconds=$((now - midnight))

if [ $seconds -gt 25200 ] && [ $seconds -lt 68400 ]
then
    /usr/bin/lookandfeeltool --apply /usr/share/plasma/look-and-feel/org.kde.breeze.desktop
else
    /usr/bin/lookandfeeltool --apply /usr/share/plasma/look-and-feel/org.kde.breezedark.desktop
fi
