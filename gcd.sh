#!/bin/bash
a=$1
b=$2

while [ "$b" -ne 0 ]; do
  remainder=$(( "$a" % "$b" ))
  a=$b
  b=$remainder
done

echo "$a"
