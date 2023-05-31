#!/bin/bash
sudo /sbin/ifconfig wlan0 down
sleep 1
sudo rm -rf /var/run/wpa_supplicant/wlan0
sudo /sbin/ifconfig wlan0 up
sleep 1
sudo /sbin/iwconfig wlan0 essid "Red Hat Guest" channel 6
sudo /usr/sbin/wpa_supplicant -B -Dwext -iwlan0 -c/etc/wpa_supplicant.conf
sudo /sbin/dhclient wlan0
