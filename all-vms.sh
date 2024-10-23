#!/bin/bash

start ()
{
    for vm in $(virsh list --all | grep -v staypuft | grep off | awk '{print $2}')
    do
        virsh start $vm
    done
}

stop ()
{
    for vm in $(virsh list --all | grep -v staypuft | grep running | awk '{print $2}')
    do
        virsh destroy $vm
    done
}

status ()
{
    virsh list --all
}

case $1 in
start)
    start
    ;;
stop)
    stop
    ;;
status)
    status
    ;;
*)
    echo "usage: $1 [start|stop|status]"
    ;;
esac
