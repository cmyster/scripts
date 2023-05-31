S=" shark"
DOO="doo doo, doo doo, doo doo;"
HUNT="Let's go hunt"
RUN="Run away"
END="It's the end"
PERSONS=( "Baby" "Sister" "Brother" "Mother" "Father" "Grandmah" "Grandpah" )

function SING ()
{
    for ((i=0; i<3; i++))
    do
        echo "${1}${2} ${DOO}"
    done
    echo "${1}${2};"
}

for p in "${PERSONS[@]}"
do
    SING "${p}" "${S}"
done

for t in "${HUNT}" "${RUN}" "${END}"
do
    SING "$t"
done
