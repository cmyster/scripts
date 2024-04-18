#!/bin/bash

# main session name
S_NAME="main"
IS_SESSION="tmux ls | grep -q $S_NAME"

if eval "$IS_SESSION"; then
	printf "Session \"%s\" already exists.\n" "$S_NAME"
	exit 1
fi

if [ ! -d /tmp/tmux-999/ ]; then
	mkdir /tmp/tmux-999
	touch /tmp/tmux-999/default
fi

tmux new-session -d -s "$S_NAME" 2>/dev/null
tmux new-window -t "$S_NAME"
tmux new-window -t "$S_NAME"
tmux send-keys -t "$S_NAME":1 "btop" Enter
tmux send-keys -t "$S_NAME":2 "irssi" Enter
tmux attach-session -t "$S_NAME"
