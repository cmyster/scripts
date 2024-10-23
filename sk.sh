#!/bin/bash

cd ~
~/scripts/pic_of_day.sh & disown &>/dev/null
. .bashrc
dbus-run-session startplasma-wayland &>logs/startplasma
