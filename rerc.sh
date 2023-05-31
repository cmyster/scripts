#!/bin/bash

# rerc (re *rc) - brings all the needed stuff for a perfect environment.
# This scripts makes it easy to deploy all the things I need from gdrive.
# When creating a new user and after installing gdrive, this brings back all
# the things I need to work perfectly and as configured.

# starting at home
cd ~

# Definitions:
# local gdrive folder
DP=~/gdrive

# Classes
# Creates links in ~ to DP folder, deletes first.
LINK_FOLDER ()
{
    for FOLDER in ${FOLDERS[@]}
    do
        rm -rf $FOLDER
        ln -s $DP/$FOLDER .
    done
}

# usually there are default folders that are created for users. Unneeded.
FOLDERS=(Videos Templates Public Pictures Music Documents)
LINK_FOLDER $FOLDERS

# Not default folders that I want to user
FOLDERS=(scripts code)
LINK_FOLDER $FOLDERS

# rc files for bash and other common applications
RC_OBJS=(.bashrc .bash_login .bash_logout .bash_profile .purple .abook .vim .vimrc .mutt .muttrc .irssi .screenrc .snownews .gnupg .conkyrc) 
for OBJ in ${RC_OBJS[@]}
do
    rm -rf $OBJ
    ln -s $DP/rc_files/$OBJ .
done

# .config is a little different. I don't want everything to be synced.
rm -rf .config
mkdir .config
CONF_FOLDS=(Thunar autostart dconf enchant gconf gtk-2.0 gtk-3.0 user-dirs.dirs user-dirs.locale xfce4)
for CONF_FOLD in ${CONF_FOLDS[@]}
do
    ln -s $DP/rc_files/.config/$CONF_FOLD ~/.config/
done


