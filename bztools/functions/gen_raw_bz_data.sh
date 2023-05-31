#!/bin/bash

gen_raw_bz_data ()
{
    try bugzilla query --field=limit=0 --from-url "$BZ_Q" --"$1" >> "$1"  || failure
}
