#!/bin/bash

LOG_DIR="/home/stack/logs"

# Number of engines to start
ENG_NUM=3

# Binary directory (i.e. if you are using a local branch vs. /usr/bin/...)
ROOT_BIN="/opt/stack/heat/bin"

# Config file
CNF_PATH="/etc/heat/heat.conf"

# The interpreter command
PY_EXE="python"

# Name of the engine
ENG="heat-engine"

# Other parts of Heat you wish to start (one of each)
NON_ENG=(
         "heat-api"
         "heat-api-cfn"
         "heat-api-cloudwatch"
        )

# Usage script.sh 0/1/anything where 0 is stop, 1 is run and anything else
# is status.

case $1 in
1)
    # TODO:
    # make this pretty with classes and shit...
    echo "Starting $ENG 1"
    $PY_EXE $ROOT_BIN/$ENG --config-file $CNF_PATH &
    sleep 1
    echo "Starting $ENG 2"
    $PY_EXE $ROOT_BIN/$ENG --config-file $CNF_PATH &
    sleep 1
    echo "Starting $ENG 3"
    $PY_EXE $ROOT_BIN/$ENG --config-file $CNF_PATH &
    sleep 1
    echo "Starting heat-api"
    $PY_EXE $ROOT_BIN/heat-api --config-file $CNF_PATH &
    sleep 1
    echo "Starting heat-api-cfn"
    $PY_EXE $ROOT_BIN/heat-api-cfn --config-file $CNF_PATH &
    sleep 1
    echo "Starting heat-api-cloudwatch"
    $PY_EXE $ROOT_BIN/heat-api-cloudwatch --config-file $CNF_PATH &
    sleep 1
    ;;
0)
    for PID in $(ps -ef | grep -E '[p]ython.*heat' | awk '{print $2}')
    do
        PEXE=$(ps --no-headers -f -p ${PID} | awk '{print $9}')
        echo -n "Found ${PEXE} (${PID})"
        echo -ne "\n"
        echo -n "Killing ${PID}"
        kill $PID &> /dev/null
        sleep 1
        ps --no-headers -f -p ${PID} &> /dev/null
        if [ $? -ne 0 ]
        then
            echo -n [ OK ]
            echo -ne "\r"
        else
            echo -n [ NOK ]
            echo -ne "\r"
        fi
    done
    ;;
*)
    echo "Heat processes:"
    ps -ef | grep -v grep | grep python | grep heat | awk '{print $2" "$9}'
    ;;
esac
