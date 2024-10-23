#!/bin/bash
tmux new-session -d 'DF'
# tmux new-window '/home/augol/DF/dwarftherapist'
tmux new-window '/bin/bash'
tmux -2 attach-session -d


#cd /home/augol/DF || exit 1
#./soundsense/soundSense.sh &
#./dwarftherapist &
#./dfhack
