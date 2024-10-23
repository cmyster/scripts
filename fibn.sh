#!/bin/bash

function fibn ()
{
    fib1=0
    fib2=1

    printf "%s, %s" "$fib1" "$fib2"

    for i in $(seq 3 "$1")
    do
        tmp=$(( fib1 + fib2 ))
        fib1="$fib2"
        fib2="$tmp"
        printf ", %s" "$tmp"
    done
}

case "$1" in
    ''|*[!0-9]*)
        printf "Needs an unsigned integer.\n"
        ;;
    0)
        printf "Needs an integer bigger than 0.\n"
        ;;
    1)
        printf "0\n"
        ;;
    2)
        printf "0, 1\n"
        ;;
    *)
        fibn "$1"
        printf "\n"
        ;;
esac
