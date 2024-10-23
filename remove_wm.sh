#!/bin/bash
# Tab Del Delete Page_Down
sleep 5
for i in $(seq 1 100)
do
sleep 0.1; xdotool key Tab
sleep 0.1; xdotool key Delete
sleep 0.1; xdotool key Tab
sleep 0.1; xdotool key Delete
sleep 0.1; xdotool key Tab
sleep 0.1; xdotool key Delete
sleep 0.1; xdotool key Tab 
sleep 0.1; xdotool key Delete
sleep 0.1; xdotool key Tab
sleep 0.1; xdotool key Delete
sleep 0.1; xdotool key Tab
sleep 0.1; xdotool key Delete
sleep 0.1; xdotool key Tab
sleep 0.1; xdotool key Tab
sleep 0.1; xdotool key Delete
sleep 0.1; xdotool key Page_Down
sleep 1
done
