#!/bin/bash

rename_file ()
{
    BZ_ID=$(grep -E "^      \"id\"" tmp_bz.json 2> /dev/null | awk '{print $NF}' 2> /dev/null | tr -d "," 2> /dev/null)
    mv tmp_bz.json "${BZ_ID}.json"
}
break_json ()
{
    while IFS= read -r line
    do
        if echo "$line" | grep -E "^    {$" &> /dev/null
        then
            rename_file
            echo "$line" >> tmp_bz.json
        fi
        echo "$line" >> tmp_bz.json
    done < <(cat json)
    rename_file
}
