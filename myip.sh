#!/bin/bash
IP_FILE=~/.myip
IP="$(ip r | grep default | tr ' ' '\n' | grep -A1 src | tail -n 1)"
echo "${IP}" >$IP_FILE
