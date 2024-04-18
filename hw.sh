#!/bin/bash
set -x

ARGS=("$@")

NUM=10
HELP="
Usage: $0 num <int> (default is 10) | div (division) | multi (multiplication)
"
DIV=1
MULTI=1

function multi() {
	for i in $(seq 1 "$NUM"); do
		num1=$(($(shuf -i 1-99 -n 1) * 10))
		num2=$(($(shuf -i 1-99 -n 1) * 10))
		printf "%s) %s × %s = \n" "$i" "$num1" "$num2"
	done
}

function div() {
	for i in $(seq 1 "$NUM"); do
		num1=$(shuf -i 1-19 -n 1)
		num2=$(($(shuf -i 1-19 -n 1) * 10))
		num3=$((num1 * num2 * 10))
		printf "%s) %s ÷ %s = \n" "$i" "$num3" "$num2"
	done
}

if [ ${#ARGS[@]} -eq 0 ]; then
	printf "%s\n" "$HELP"
	exit 1
else
	for i in $(seq 1 ${#ARGS[@]}); do
		if [[ "${ARGS[$i]}" == "num" ]]; then
			NUM=$i
		fi
		if [[ "${ARGS[i]}" == "div" ]]; then
			DIV=0
		fi
		if [[ "${ARGS[i]" == "multi" ]]; then
			MULTI=0
		fi
	done
fi

if [ $MULTI -eq 0 ] || [ $DIV -eq 0 ]; then
	if [ $MULTI -eq 0 ]; then
		multi
	fi
	if [ $DIV -eq 0 ]; then
		div
	fi
else
	printf "%s\n" "$HELP"
fi
