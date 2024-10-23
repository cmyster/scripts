#!/bin/bash
set -x
for i in {1..15}; do # Use i to loop from "1" to "100", inclusive.
	echo $i
	((i % 3)) &&  # If i is not divisible by 3...
		x= ||        # ...blank out x (yes, "x= " does that).  Otherwise,...
		x=Fizz       # ...set (not append) x to the string "Fizz".
	((i % 5)) ||  # If i is not divisible by 5, skip (there's no "&&")...
		x+=Buzz      # ...Otherwise, append (not set) the string "Buzz" to x.
	echo ${x:-$i} # Print x unless it is blanked out.  Otherwise, print i.
done
