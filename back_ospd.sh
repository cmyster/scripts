#!/bin/bash
if [ -f /home/rhos-qe/ospd.tar ]
then
    mv /home/rhos-qe/ospd.tar /root/FIX/
    chown augol:users /root/FIX/ospd.tar
    chmod 0644 /root/FIX/ospd.tar
    mv /root/FIX/ospd.tar /home/augol/share/
fi
