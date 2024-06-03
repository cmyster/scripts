#!/bin/bash

# main session name
S_NAME="main"
IS_SESSION="tmux ls | grep -q $S_NAME"

if eval "$IS_SESSION"; then
	tmux -2 a
	exit 0
fi

if [ ! -d /tmp/tmux-1000/ ]; then
	mkdir /tmp/tmux-1000
	touch /tmp/tmux-1000/default
fi

tmux -2 new-session -d -s "$S_NAME" 2>/dev/null
tmux -2 new-window -t "$S_NAME"
tmux -2 new-window -t "$S_NAME"
tmux -2 send-keys -t "$S_NAME":1 "irssi" Enter
tmux -2 attach-session -t "$S_NAME"
