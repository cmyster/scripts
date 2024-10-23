SCREENSHOT="$HOME/Pictures/screenshots/screenshot.png"
grim -g "$(slurp)" "$SCREENSHOT"
swappy -f "$SCREENSHOT" -o "$SCREENSHOT"
