#!/bin/bash
if [ $(xprintidle) -gt 239900 ]
then
    /usr/bin/xflock4
fi
