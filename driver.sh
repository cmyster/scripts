#!/bin/bash
cd ~/gdrive || exit 1
drive push -no-prompt -hidden --ignore-name-clashes
