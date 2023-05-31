#!/bin/bash
# This script will look for installed packages
# and will print results per search request

# pkgtools save package info here
PGK_DIR=/var/log/packages

# saving search argument to be manipulated later
ARGS=("$@")

# there should be at least one search criteria
# if not, print the usage
if [ "$ARGS" == "" ]
then
	echo "Usage: $0 [package_A] [package_B] ... [package_N]"
	exit 1
fi

# each search criteria will be checked

results=0
total_results=0

for ARG in "${ARGS[@]}"
do
	# to make sure grep works OK, a search criteria should not start with a "-"
	# if it does, remove it (maybe it was a typo)
	if [ "${ARG:0:1}" == "-" ]
	then
		ARG=${ARG:1:${#ARG}}
	fi

	# creats an array from the reults of 'ls | grep'
	# if there are no results, print message, else, for-loop the array and print
	PKGS=(`ls $PGK_DIR | grep -i "$ARG"`)
	if [ "$PKGS" == "" ]
	then
		echo "No packages found!"
	else
		for PKG in "${PKGS[@]}"
		do
			echo $PKG | grep -i "$ARG" --color=never
			results=$(( results + 1 ))
		done
	fi

	total_results=$(( total_results + results ))
done
