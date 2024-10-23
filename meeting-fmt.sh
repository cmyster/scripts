#!/bin/bash
LEN=$1
SPACES=""

for space in $(seq 1 $2)
do
    export SPACES=$SPACES" "
done

while IFS= read -r LINE
do
    if [ ${#LINE} -gt $LEN ]
    then
        FIRST=true
        SECTIONS=$(( ${#LINE} / $LEN + 1))
        for S in $(seq 1 $(( $SECTIONS )) )
        do
            for I in $(seq $LEN -1 1)
            do
                if [[ "$(echo ${LINE:$(( $I - 1 )):1})" == "" ]]
                then
                    if $FIRST
                    then
                        echo "${LINE:0:$I}"
                        export FIRST=false
                    else
                        echo "$SPACES${LINE:0:$I}"
                    fi
                    LINE=${LINE:$I}
                    break
                fi
            done
        done
    else
        echo "$LINE"
    fi
done
