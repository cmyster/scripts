#!/bin/bash

cnf_src="/opt/stack/tempest/etc/tempest.conf"
cnf_dst="/home/stack/tempest.conf"

grep -v "#" $cnf_src | sed '/^$/d' | sed 's/\[/\n[/g' > $cnf_dst

SERVER=$(grep rabbit_hosts $cnf_dst | awk '{print $NF}')
sed -i 's/127.0.0.1/'$SERVER'/g' $cnf_dst

if [[ $1 == "-c" ]]
then
    remote_user=augol
    HOST=$(who | grep stack | grep pts\/ | awk '{print $NF}' | tr -d "\(" | tr -d "\)" | head -n 1)
    scp $cnf_dst $remote_user@$HOST:/home/$remote_user/
fi
