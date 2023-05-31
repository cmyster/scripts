create_matrix()
{
    base_depth=$(( $(echo "$CWD" | tr "/" "\n" | wc -l) + 2 ))
    find "$CWD/data" -mindepth 1 -type f -name "*.log" \
        | xargs /bin/grep -H . \
        | cut -d "/" -f ${base_depth},$(( base_depth + 2 ))-20 > index
}

