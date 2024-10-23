#!/bin/bash

if [[ "$EUID" != 0 ]]; then
	printf "This script can only be run as root user.\n"
	exit 1
fi
while true; do
	shutdown -c
	sleep 5
done
