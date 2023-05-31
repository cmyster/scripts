#!/bin/bash

# Killing the processes of a certain user after exiting X.
# I do not need anything running in the background after exiting X server.

for proc in $(ps u | grep $(whoami) | awk '{print $2}')
do
    kill $proc
done

