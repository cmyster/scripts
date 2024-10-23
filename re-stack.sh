#!/bin/bash

ROOT_PATH="/opt/stack"
UPDATE_LOG="/tmp/updating"
TMP_LIST="/tmp/piplist"

cd /home/stack

echo "Stopping any and all devstack processes"
devstack/unstack.sh &> /dev/null

echo "Cleaning devstack logs"
rm -rf $ROOT_PATH/logs/*

echo "Updating OS"
sudo yum update -y &> $UPDATE_LOG

echo "Checking if there were any kernel changes"
grep "kernel-" $UPDATE_LOG
if [ $? -eq 0 ]
then
    echo "A newer kernel package was installed. This machine will reboot now. Please rerun ${0}."
    sudo reboot
fi

echo "Creating a list of packages that were installed from *requirements.txt files"
find $ROOT_PATH -type f -name "*requirements.txt" | \
    xargs cat | \
    tr ">" " " | \
    tr "=" " " | \
    cut -d " " -f 1 | \
    sort | uniq | \
    grep -v "#" | grep -v pip > $TMP_LIST

echo "Going over the list of packages pip installed and removing them"
TOTS=$(cat $TMP_LIST | wc -l)
INDEX=0
for pip_pkg in $(cat $TMP_LIST)
do
    sudo pip uninstall $pip_pkg -y &> /dev/null
    AT=$(bc -l <<< "$INDEX/$TOTS*100")
    PER=$(echo $AT | awk '{printf("%.2f%\n", $1)}')
    echo -n $PER
    echo -ne "\r"
    INDEX=$(( $INDEX + 1 ))
done

echo -ne "\r"

echo "Cleaning leftovers that pip sometime keeps"
TOTS=$(cat $TMP_LIST | wc -l)
INDEX=0
for pip_pkg in $(cat $TMP_LIST)
do
    sudo pip uninstall $pip_pkg -y &> /dev/null
    AT=$(bc -l <<< "$INDEX/$TOTS*100")
    PER=$(echo $AT | awk '{printf("%.2f%\n", $1)}')
    echo -n $PER
    echo -ne "\r"
    INDEX=$(( $INDEX + 1 ))
done

echo -ne "\n"
echo "Done"

echo "Cleaning packages not installed from *requirements.txt files"
sudo pip uninstall -y virtualenv &> /dev/null

echo "Releasing loopX"
sudo /usr/bin/systemd-run /usr/sbin/lvm pvscan --cache &> /dev/null
sudo vgremove -f stack-volumes-default &> /dev/null

echo "Updating devstack from master"
cd devstack
git checkout master &> /dev/null
git pull &> /dev/null
cd ..

echo "System should be clean now. Running stack.sh"
rm -rf devstack/install.log
devstack/stack.sh &> devstack/install.log &
TOTS=13600
RUNNING=true
while $RUNNING
do
    LINES=$(cat devstack/install.log | wc -l)
    AT=$(bc -l <<< "$LINES/$TOTS*100")
    PER=$(echo $AT | awk '{printf("%.2f%\n", $1)}')
    echo -n $PER
    echo -ne "\r"
    ps -ef | grep -v "grep\|re-stack" | grep "stack.sh" &> /dev/null
    RES=$?
    if [ $RES -eq 1 ]
    then
        export RUNNING=false
        AT=100
        PER=$(echo $AT | awk '{printf("%.2f%\n", $1)}')
        echo -n $PER
        echo -ne "\n"
    fi
    sleep 1
done

echo "Done"

echo "packaging accrc"
rm -rf accrc.tar
tar cf accrc.tar devstack/accrc
