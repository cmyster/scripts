#!/usr/bin/bash

REMOTE_USER="augol"
LOCAL_USER="stack"

IP=$(who | grep $LOCAL_USER | tr -d "()" | awk '{print $NF}' | uniq)
scp $1 ${REMOTE_USER}@${IP}:/home/${REMOTE_USER}
