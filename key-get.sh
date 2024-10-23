#!/bin/bash

RCFILE=overcloudrc

ARGS=("$@")
if [ ${#ARGS[@]} -ne 1 ]
then
    echo "Usage: $0 API (e.g. roles, domains, users etc.)"
    exit 1
fi

if [ ! -r $RCFILE ]
then
    echo "Error: $RCFILE not found or readable"
    exit 1
fi

source $RCFILE
LINK=$(echo $OS_AUTH_URL | cut -d"/" -f 1-3)
TOKEN=$(keystone token-get 2> /dev/null | grep " id " | awk '{print $4}')
curl -H "x-auth-token:$TOKEN" ${LINK}/v3/${1} | python -mjson.tool
