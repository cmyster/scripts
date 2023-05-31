#!/bin/bash
xrandr --output DVI-I-1 --auto
xrandr --output DVI-I-1 -s 1920x1080
xrandr --output VGA-1 --right-of DVI-I-1
xrandr --output DVI-I-1 --preferred
xrandr --output DVI-I-1 --primary
sleep 5
