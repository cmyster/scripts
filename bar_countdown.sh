#!/bin/bash

# This script paints a bar that grows shorter as time progresses.
# To calculate things, we're using bc, so make sure it's installed.

if ! which bc &>/dev/null; then
	printf "%s\n" "Please make sure that bc is installed."
	exit 1
fi

# How many glyphs should the BAR have.
LENGTH="$1"
# How long should each tick be in seconds.
WAIT="$2"
# Must have, will be used for the body glyph of the BAR.
BAR_BODY="$3"
# Optional, will be used for the leftmost glyph.
BAR_START="$4"
# Optional, will be used for the rightmost glyph.
BAR_END="$5"

# The required parameters need to be set.
if [ -z "$LENGTH" ] || [ -z "$WAIT" ]; then
	printf "Usage: %s [length] [time] [body] [start] [end]\n\n" "$0"
	printf "%s\n" \
		"  length: How many glyphs the bar should have. This can change slightly to have smoother run" \
		"  time:   Overall (rounded) time to wait." \
		"  body:   Optional, the glyph to use for the body. If none is set, use \"#\"" \
		"  start:  Optional, leftmost glyph." \
		"  end:    Optional, rightmost glyph."
	exit 1
fi

if [ -z "$BAR_BODY" ]; then
	BAR_BODY="#"
fi

# We don't want the length of the bar to be too long, so it can fit in a single, short line.

if [ "$LENGTH" -gt 40 ]; then
	printf "The length of the bar is too long.\n"
	exit 1
fi

# Calculations that are used for sleep and BAR lenght later.
if [ $LENGTH -gt $WAIT ]
then
	LENGTH=$((LENGTH + LENGTH % WAIT))
else
	LENGTH=$((LENGTH + WAIT % LENGTH))
fi

TICK=$(bc <<<"scale=3; $WAIT / $LENGTH")

# This function builds the BODY (length) of the BAR.
function build_body() {
	export BODY=""
	for ((i = 0; i < $1; i++)); do
		BODY="${BODY}${BAR_BODY}"
	done
	export BODY
}

# Counting down and decreasing BAR length.
for ((i = LENGTH; i > 0; i--)); do

	if [ "$i" -eq 1 ]; then
		BAR="${BAR_START}ALMOST...${BAR_END}"
	else
		# Building the BAR
		build_body "${i}"
		BAR="${BAR_START}${BODY}${BAR_END}"
	fi
	# Clearing the BAR:
	# Returning to the beginning of the line,
	# printing spaces to override the previous BAR,
	# and returning again to the beginning of the line.
	printf "\r                                          \r"
	# Printing the BAR
	printf "%s" "$BAR"

	sleep "$TICK"
done

printf "\r                                          \r"
