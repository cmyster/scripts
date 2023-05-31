#!/bin/bash

# starting parameters
homedir=/home/ubuntu/replication/tungsten/tungsten-replicator/bin
program=trepctl

# control parameters
service_param=-service
start_param=online
stop_param=offline
status_param=status
skip_param=-skip-seqno

function check_state ()
{
	for service in dev1 mddb1 mddb2
	do
		state=`$homedir/$program $service_param $service $status_param | grep state | awk '{print $3}'`
		if [[ "$state" == OFFLINE* ]]
		then
			bad_service=$service
			return
		else	
			bad_service=""
		fi
	done
}

function get_seqno ()
{
	seqno=`$homedir/$program $service_param $bad_service $status_param | grep pendingError | awk '{print $6}' | sed 's/seqno=//g'`
	return
}

function skip_seqno ()
{
	$homedir/$program $service_param $bad_service $start_param $skip_param $seqno
}

function execute ()
{
	check_state
	if [ "$bad_service" == "" ]
	then
		echo "All services are OK"
	else
		get_seqno
		echo "$bad_service has errors, skipping faulty seqno $seqno"
		skip_seqno

		# letting the faulty server run for a bit and then rechecking
		sleep 10
		execute
	fi
}

execute

