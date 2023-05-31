# !/bin/bash
# /etc/init.d/trep.sh

PROG=/home/ubuntu/replication/tungsten/tungsten-replicator/bin/replicator
CHECK=/home/ubuntu/scripts/skip_err.sh

case "$1" in
	start)
		$PROG start
		/home/ubuntu/scripts/skip_err.sh &
	;;
	stop)
		$PROG stop
	;;
	status)
		$PROG status
	;;
	restart)
		$PROG restart
		/home/ubuntu/scripts/skip_err.sh &
	;;
	*)
	echo "Usage: $0 {start|stop|status|restart}"
	exit 1
	;;
esac

exit 0
