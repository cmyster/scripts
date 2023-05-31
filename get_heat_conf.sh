#!/bin/bash
local_user=stack
remote_user=augol
cnf_src="/etc/heat/heat.conf"
cnf_dst="/home/stack/heat.conf"
grep -v "#" $cnf_src | sed '/^$/d' | sed 's/\[/\n[/g' > $cnf_dst
SERVER=$(grep rabbit_hosts $cnf_dst | awk '{print $NF}')
sed -i 's/127.0.0.1/'$SERVER'/g' $cnf_dst
if [[ $1 == "-c" ]]
then
HOST=$(who | grep stack | grep pts\/0 | awk '{print $NF}' | tr -d "\(" | tr -d "\)")
    scp $cnf_dst $remote_user@$HOST:/home/$remote_user/
fi
