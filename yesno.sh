#!/bin/bash
read -r input
if [[ $input == "Y" || $input == "y" ]]; then
	echo OK
else
	echo so no
fi
