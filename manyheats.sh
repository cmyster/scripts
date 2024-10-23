#!/usr/bin/bash

# range to the number of engines
max_engines=10
min_engines=1

create_engine ()
{
    python /opt/stack/heat/bin/heat-engine --config-file=/etc/heat/heat.conf &> /dev/null &
}

kill_engine ()
{
    kill -9 $1 &> /dev/null
} 

rand_engine_pid ()
{
    index=$[ $min_engines + $[ $RANDOM % $max_engines ] ]
    engines=($(ps -ef | grep heat-engine | grep -v grep | awk '{print $2}'))
    eng_pid=${engines[$index]}
    return
}

get_current_running ()
{
    current=$(ps -ef | grep heat-engine | grep -v grep | wc -l)
    return
}

what_to_do ()
{
    get_current_running
    echo "[`date +%T`] - Current number of running heat-engines: $current"
    if [ $current -lt $max_engines ]
    then
        echo "[`date +%T`] - Creating a new engine"
        create_engine 
    else
        rand_engine_pid    
        echo "[`date +%T`] - Killing an existing engine with PID - $eng_pid"
        kill_engine $eng_pid
    fi 
}

half ()
{
    get_current_running
    range=$((current / 2))
    for (( i=1; i<=$range; i++ ))
    do
        rand_engine_pid
        kill_engine $eng_pid
    done
}

index=$min_engines
while true
do
    if [ $index -eq $max_engines ]
    then
        echo "[`date +%T`] - HALFING!"
        half
        index=$min_engines
    fi

    what_to_do
    sleep 1
    ((index += 1))
done

