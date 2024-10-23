#!/bin/bash

##############################################################################
#                              build-tomcat.sh                               # 
# This small script uses dialog to generate selectable options for the user. #
# Those options are later passed to ant so it can build a fresh build.       #
# The build is always done on latest revision and on a 'clean' branch.       #
# The output of this script is a complete version compressed in 7z.          #
# This script expects the following:                                         #
#   - a working branch is checked out (doesn't have to be updated).          #
#   - user is not expected to enter username/password for svn update.        #
#   - For all the dialogs in the script: Dialog.                             #
#   - To update branch: subversion 1.7+.                                     #
#   - To compile: Oracle's JDK 1.6.45+ and apachec-ant 1.8.2.                #
#   - To compress: p7zip                                                     #
#   - To copy the file remotely and login later: scp and ssh.                #
##############################################################################

# if debugging is needed...
# set -x

# region classes

# rotate the cursor clockwise every 1s
rotateCursor() {
    case $toggle
    in  
        1)  
        echo -n $1" \  "$2
        echo -ne "\r"
        toggle="2"
        ;;  

        2)  
        echo -n $1" |  "$2
        echo -ne "\r"
        toggle="3"
        ;;  

        3)  
        echo -n $1" /  "$2
        echo -ne "\r"
        toggle="4"
        ;;  

        *)  
        echo -n $1" -  "$2
        echo -ne "\r"
        toggle="1"
        ;;  
    esac
}

# is there a running process with given PID
check_running() {
    ps -p $1 &> /dev/null
    RET_VAL=$?
    if [ $RET_VAL -ne 0 ] 
    then
        export RUNNING=false
    fi  
}

# basic logger
echo_log() {
    echo -ne $1
}

# write OK to certain jobs
echo_success() {
    echo -ne $"\t\t\t\t\t[  OK  ]"
    echo -ne "\r\n"
}

# write FAIL to certain jobs
echo_failed() {
    echo -ne $"\t\t\t\t\t[ FAIL ]"
    echo -ne "\r\n"
}

# endregion classes

# folders
LOG_DIR=/home/ct/logs
CWD=$(pwd)
cd .. &> /dev/null
BUILD_ROOT=$(pwd)
BUILD_NAME=$(pwd | awk -F/ '{print $NF}')
VER_DIR=/home/ct/versions
BUILD_DIR=$VER_DIR/$BUILD_NAME
mkdir -p $LOG_DIR $BUILD_DIR &> /dev/null

# general properties
RUNNING=true
BUILD_ENV=tomcat
BUILD_TIME=$(date +%d%m%a-%H%m)
DIA_LOG=dialog.tmp
SVN_LOG=$LOG_DIR/svn-$BUILD_ENV.$BUILD_TIME.log
Z7_LOG=$LOG_DIR/7z-$BUILD_ENV.$BUILD_TIME.log
B_TITLE="CT Version Building Scrip"

if [ -f $DIA_LOG ]
then
    echo_log "\n Note: The script did not exist cleanly last time it was run.\n"
    rm -rf $DIA_LOG
fi

# while at BUILD_ROOT, lets cleat it from old builds
find -type d -name build | xargs rm -rf &> /dev/null
cd $CWD &> /dev/null
rm -rf Version*

# build-time parameters (note the Windows paths, should be different for *NIX)
# export CATALINA_HOME="/usr/local/tomcat"
# export OPENEJB_HOME="/usr/local/tomcat/webapps/openejb"
export CATALINA_HOME="C:\Apache\Tomcat"
export OPENEJB_HOME="C:\Apache\Tomcat\webapps\openejb"
export ANT_OPTS="-XX:MaxPermSize=1024m -Xms512m -Xmx512m"
BUILD_FILE=./build.properties
LOG_FILE=$LOG_DIR/build-$BUILD_ENV.$BUILD_TIME.log
touch $LOG_FILE

# updating subversion to latest revision
RUNNING=true
cd $BUILD_ROOT
svn update &> $SVN_LOG &
SVN_PID=$!
sleep 1

while $RUNNING
do
    rotateCursor "updating build to latest version: "
    check_running $SVN_PID
    sleep 1
done

grep "Updated to revision\|At revision" $SVN_LOG &> /dev/null
if [ $? -ne 0 ]
then
    echo_failed
    echo_log "please check $LOG_FOLDER/$SVN_LOG to see why svn failed.\n"
    rm -rf $DIA_LOG
    exit 1
else
    echo_success
	echo_log "$(grep "Updated to revision\|At revision" $SVN_LOG)\n"
fi

# creating a list of build XMLs
cd $CWD
COMMAND=""
xml_array=( $(ls *.xml | tr "*" " ") )

len=${#xml_array[@]}
for (( i=0; i<$len; i++ ))
do
    COMMAND+=$(echo $i ${xml_array[$i]}" ")
done

# using dialog to select the build XML
dialog --backtitle "$B_TITLE" \
       --title "Build XML Selection" \
       --menu "Select build XML" 11 30 $len $COMMAND 2> $DIA_LOG

# if cancel was pressed, exit
RET_VAL=$?
if [ $RET_VAL -ne 0 ]
then
    rm -rf $DIA_LOG
    exit 1
fi

# setting the build XML
result=$(cat $DIA_LOG)
build_xml=${xml_array[$result]}

echo_log "$build_xml selected\n"

rm -rf $DIA_LOG

# getting list of build names
COMMAND=""
cd deploy
dep_array=( $(ls *build.properties | awk -F- '{print $1}') )
cd ..

len=${#dep_array[@]}
for (( i=0; i<$len; i++ ))
do
    COMMAND+=$(echo $i ${dep_array[$i]}" ")
done

# using dialog to select the build
dialog --backtitle "$B_TITLE" \
       --title "Property Selection" \
       --menu "Select build properties" 11 30 $len $COMMAND 2> $DIA_LOG
# if cancel was pressed, exit
RET_VAL=$?
if [ $RET_VAL -ne 0 ]
then
    rm -rf $DIA_LOG
    exit 1
fi

# setting the correct build properties 
result=$(cat $DIA_LOG)
echo deploy.name = ${dep_array[$result]} > $BUILD_FILE
echo_log "using $(cat $BUILD_FILE)\n"
rm -rf $DIA_LOG

# before calling ant, lets clean and print all the parameters used:
clear
echo_log "starting build process at $(date)\n"
echo_log "writing to logfile $LOG_FILE\n"
echo_log "using build file $build_xml\n"
echo_log "using the build property $(cat $BUILD_FILE)\n"

# calling ant
RUNNING=true
ant -f ./$build_xml -propertyfile $BUILD_FILE -logfile $LOG_FILE &> /dev/null &
echo_log "starting ant...\n"
sleep 2
ANT_PID=$(ps -ef | grep "java\|ant-launcher" | grep -v grep | awk '{print $2}')

while $RUNNING
do
    check_running $ANT_PID
    LINE=$(cat $LOG_FILE | wc -l)
    export PERCENT=$(( $LINE * 100 / 4600 ))
    rotateCursor "building: " "$PERCENT%"
    sleep 1
done

if [ $PERCENT -ne 100 ]
then
    rotateCursor "building: " "100%"
    export PERCENT=0
fi

# checking for errors in the log file
grep -i error $LOG_FILE &> /dev/null
RET_VAL=$?
if [ $RET_VAL -eq 0 ]
then
    echo_failed
    echo_log "the log file $LOG_FILE contains errors!\n"
    dialog --backtitle "$B_TITLE" \
           --title "continue" \
           --yesno "errors found! continue anyway?" 6 42
    RET_VAL=$?
    if [ $RET_VAL -ne 0 ]
    then
        echo_log "version folder is ready for later use.\n"
        rm -rf $DIA_LOG
        exit 1
    fi
else
    echo_success
fi

# checking for ANT final status in the log file.
# this does not mean that there are no build errors.
grep "BUILD SUCCESSFUL" $LOG_FILE &> /dev/null
RET_VAL=$?
if [ $RET_VAL -ne 0 ]
then
    echo_log "\nplease check $LOG_FILE to see why ANT failed.\n"
    rm -rf $DIA_LOG
    dialog --backtitle "$B_TITLE" \
           --title "continue" \
           --yesno "ANT could not finish the build! continue anyway?" 6 42
    RET_VAL=$?
    if [ $RET_VAL -ne 0 ]
    then
        echo_log "version folder is ready for later use.\n"
        rm -rf $DIA_LOG
        exit 1
    fi
fi

# if we reached this place, the build was OK or we wanted to go on anyway
echo_log "$(tail $LOG_FILE | grep BUILD)\n"
echo_log "$(tail $LOG_FILE | grep Total)\n"

# compressing
RUNNING=true
ver_folder=$(ls -l | grep Version | awk '{print $NF}' | awk -F/ '{print $1}')
START_TIME=$(date +%s)
7z a $ver_folder.7z $ver_folder &> $Z7_LOG &
Z7_PID=$!
sleep 1

while $RUNNING
do
    check_running $Z7_PID
    LINE=$(cat $Z7_LOG | wc -l)
    export PERCENT=$(( $LINE * 100 / 410 ))
    rotateCursor "compressing: " "$PERCENT%"
    sleep 1
done

END_TIME=$(date +%s)

if [ $PERCENT -ne 100 ]
then
    rotateCursor "compressing: " "100%"
    export PERCENT=0
fi

# checking for 7z final status in the log file
grep "Everything is Ok" $Z7_LOG &> /dev/null
RET_VAL=$?
if [ $RET_VAL -eq 0 ]
then
    echo_success
else
    echo_failed
    echo_log "\nplease check $Z7_LOG to see why 7Z failed.\n"
    rm -rf $DIA_LOG
    exit 1
fi

echo_log "compression time: $(date -u -d @$(($END_TIME-$START_TIME)) +%T)\n"

rm -rf $ver_folder

# copying the version and logging into the remote server needs more info:

# the script reads itself and looks for 3 x # to indicate for it that lines
# starting with 3 '#' are server information that is predefined. to read the
# script even if it was renamed we take $0 as parameter. 
script_exe=$0

# these are the pre-defined servers. the scripts expects that you can connect
# via ssh to the remote server.
#   NAME       IP               USER
##  example    127.0.0.1        user
### dev1       10.0.0.141       ct
### dev2       10.0.0.142       ct
### support    46.137.110.154   ctadmin
### mydevice   54.247.169.25    ctadmin

# defining arrays from each line
name_array=( $(cat $script_exe | grep -v "array=(" | grep "###" | awk '{print $2}') )
addr_array=( $(cat $script_exe | grep "###" | grep -v "array=(" | awk '{print $3}') )
user_array=( $(cat $script_exe | grep "###" | grep -v "array=(" | awk '{print $4}') )

# this class will return returned_index to select the common index for all arrays
server_from_list ()
{
    DIA_LOG=./dialog.log
    command=""
    name_len=${#name_array[@]}
    for (( i=0; i<$name_len; i++ ))
    do
            command+=$(echo $i ${name_array[$i]}" ")
    done

    dialog --clear \
           --backtitle "$B_TITLE" \
           --title "Server Selection" \
           --menu "Select predefined server:" \
           11 30 $name_len $command 2> $DIA_LOG

    retval=$?
    if [ $retval != 0 ]
    then
        clear
        echo Cancelled
        rm $DIA_LOG
        exit 1
    fi

    returned_index=$(cat $DIA_LOG)
    return
    rm -rf $DIA_LOG
}

dialog --backtitle "$B_TITLE" \
       --title "Distribute Version" \
       --yesno "shall I copy this version remotely?" 6 42
RET_VAL=$?
if [ $RET_VAL -ne 0 ]
then
    export remote=false
    echo_log "version file is ready for later use.\n"
else
    export remote=true
    server_from_list
    export CREDS="${user_array[ $returned_index ]}@${addr_array[ $returned_index ]}"
    REMOTE_DIR="/home/${user_array[ $returned_index ]}"
    echo_log "copying $ver_folder.7z to $CREDS:$REMOTE_DIR\n"
    scp $ver_folder.7z $CREDS:$REMOTE_DIR
    if [ $? -ne 0 ]
    then
        echo_log "version was not copied successfully and is ready for later use.\n"
    fi
fi

if $remote
then
    dialog --backtitle "$B_TITLE" \
           --title "Remote Login" \
           --yesno "shall I login to ${name_array[ $returned_index ]}?" 6 42
    RET_VAL=$?
    if [ $RET_VAL -eq 0 ]
    then
        echo_log "connecting to ${name_array[ $returned_index ]}\n"
        ssh $CREDS
    fi
fi

echo_log "$ver_folder.7z can be found in $BUILD_DIR\n"
mv $ver_folder.7z $BUILD_DIR &> /dev/null
rm -rf $DIA_LOG

echo_log "ALL DONE\n"

exit 0
