#!/bin/bash

set -x

devhome=/home/stack/devstack
stackhome=/opt/stack
tmplog=/tmp/devstack_yum_update.log

rm -rf $tmplog

cd $devhome

./unstack.sh &> /dev/null
if [ $? -ne 0 ]
then
    echo "unstack failed"
    exit 1
fi 

if [ -d $stackhome ]
then
    sudo rm -rf $stackhome
fi

sudo yum update -y &> $tmplog
grep 'kernel-[0-9]\.' $tmplog
if [ $? -eq 0 ]
then
    echo "new kernel was installed."
    echo "please re-run $0 after restart"
    sudo reboot
    exit 0
fi

cd $devhome

git pull &> /dev/null
if [ $? -ne 0 ]
then
    echo "git pull failed"
    exit 1
fi 

./stack.sh

rm -rf $tmplog
