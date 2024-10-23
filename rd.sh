#!/bin/bash
#
# TODO:
# move all complex code in MAIN to be in classes
# move all echo to printf whereever we can
#
# rd.sh ,tries to make rdesktop easier with saved parameters
# steps:
# 1. tests (binary in use and syntax)
# 2. find input host argument position in an array
# 3. if more than one monitor attached, use the largest resolution
#    (resolution is needed anyway since default is 800x600)
# 4. fix resolution so window decoration will not cut the screen
#
# Tweak-ables:
# DATA REGION, folder, nameserver, x_min, y_min
#
# dependencies:
# which,rdesktop,xrandr,dialog,ssh,sshpass

#============================================================
#= START DATA REGION                                        =
#= DATA: arrays are built from lines that start with 3x'#'  =
#============================================================

#   NAME      IP               USER           PASSWORD
##  example   127.0.0.1        user           password
### rhos-qe   10.35.7.199      Administrator  1rhos)qe
### rhos-q1   10.35.7.199      Administrator  1rhos)qe
### rhos-q2   10.35.7.199      Administrator  1rhos)qe
### rhos-q3   10.35.7.199      Administrator  1rhos)qe
### rhos-q4   10.35.7.199      Administrator  1rhos)qe
### rhos-q5   10.35.7.199      Administrator  1rhos)qe

#===================
#= END DATA REGION =
#===================

#==========================================================
#= START SETUP REGION                                     =
#= SETUP: definition of a few parameters and sanity tests =
#==========================================================

# uncomment to debug
# set -x

# how was the script called
script_exe=$0

# local folder for use
folder=~/rd

# which dialog program to use
dialog=dialog

# saving the arguments
arguments="$@"

# temp folder to be used
TMP_DIR=~/.tmp/
mkdir -p $TMP_DIR

# using dialog to print stuff
which $dialog &> /dev/null
retval=$?
if [ $retval == 1 ]
then
	echo "'which' cannot find $dialog please make sure it is installed properly"
	exit 1
else
	export DIALOG=`which $dialog`
fi

# can't do anything without rdesktop and connection programs
which rdesktop &> /dev/null
retval=$?
if [ $retval == 1 ]
then
	$DIALOG --title	"Missing Program" --msgbox "'which' cannot find rdesktop. Please make sure it is installed properly" 8 33
	exit 1
else
	export RDESKTOP=`which rdesktop`
fi

which xrandr &> /dev/null
retval=$?
if [ $retval == 1 ]
then
	$DIALOG --title	"Missing Program" --msgbox "'which' cannot find xrandr. Please make sure it is installed properly" 8 33
	exit 1
else
	export XRANDR=`which xrandr`
fi

which ssh &> /dev/null
retval=$?
if [ $retval == 1 ]
then
	$DIALOG --title	"Missing Program" --msgbox "'which' cannot find ssh. Please make sure it is installed properly" 8 33
	exit 1
else
	export SSH=`which ssh`
fi


# these are the arrays. they come earlier for definition and dialog purpose
name_array=(`cat $script_exe | grep -v "array=(" | grep "###" | awk '{print $2}'`)
ip_array=(`cat $script_exe | grep "###" | grep -v "array=(" | awk '{print $3}'`)
user_array=(`cat $script_exe | grep "###" | grep -v "array=(" | awk '{print $4}'`)
pass_array=(`cat $script_exe | grep "###" | grep -v "array=(" | awk '{print $5}'`)

#====================
#= END SETUP REGION =
#====================

#==================================================================
#= START FUNCTIONS REGION                                         =
#= FUNCTIONS: defining all the used functions before calling them =
#==================================================================

# defines usage text
usage_text ()
{
printf %s "\
Usage : [ -h -s -r ] [ Optional : SERVER ]
$script_exe [ -h ] print this help message and exit
$script_exe [ -s ] use SSH to connect
$script_exe [ -r ] use rdesktop to connect

example 1: $script_exe [-r or -s] [SERVER]
will try to use rdesktop or ssh to connect to a known SERVER

Example 2: $script_exe [-r or -s] [example.com]
try to connect with rdesktop or ssh and let them try and resolve the host

Example 3: $script_exe [-r or -s]
will open a list of known hosts and connect to the chosen one with rdesktop or ssh

"
}

get_max_string_length ()
{
	max_string_length=0

	for name in ${name_array[@]}
	do
		if [ ${#name} -gt $max_string_length ]
		then
			export max_string_length=${#name}
		fi
	done

	for ip in ${ip_array[@]}
	do
		if [ ${#ip} -gt $max_string_length ]
		then
			export max_string_length=${#ip}
		fi
	done

	for user in ${user_array[@]}
	do
		if [ ${#user} -gt $max_string_length ]
		then
			export max_string_length=${#user}
		fi
	done

	for pass in ${pass_array[@]}
	do
		if [ ${#pass} -gt $max_string_length ]
		then
			export max_string_length=${#pass}
		fi
	done
}

# prints usage with max_string_length as filter for printf
usage_known ()
{
	max_string_length=$(( max_string_length + 1 ))
	for (( index=0; index<${#name_array[@]}; index++ ))
	do
		printf "%-${max_string_length}s" \
		${name_array[ $index ]} \
		${ip_array[ $index ]} \
		${user_array[ $index ]} \
		${pass_array[ $index ]}
		echo ""
	done
}

# returns the position of the server argument in the array
get_index ()
{
	local index=1
	for host_name in "${name_array[@]}"
	do
		if [ "$host_name" = "$SERVER" ]
		then
			returned_index=$index
			return
		fi

		((index += 1))
	done
}

# returns largest resolution available
get_resolution ()
{
	# ask xrandr which monitors are connected
	local xlog=$TMP_DIR/out.x
	touch $xlog
	$XRANDR > $xlog

	# how many monitors are there?
	local mons=`cat $xlog | grep connected | grep -v dis | awk '{print $1}' | \
	wc -l`

	# if there is only 1 monitor, return its resolution
	if [ "$mons" -eq "1" ]
	then
		returned_res=`echo \`cat $xlog | grep -v conn | grep + | \
		awk '{print $1}'\` | awk '{print $1}'`
		return
	fi

	# if we continue, which resolution is higher?
	# TODO: something more generic is needed, that can get N number of monitors
	#
	# get both resolutions
	local res_a=`echo \`cat $xlog | grep -v conn | grep + | \
	awk '{print $1}'\` | awk '{print $1}'`
	local res_b=`echo \`cat $xlog | grep -v conn | grep + | \
	awk '{print $1}'\` | awk '{print $2}'`

	#convert to total pixels
	local pixels_a=$(( ${res_a/"x"/*} ))
	local pixels_b=$(( ${res_b/"x"/*} ))

	# return bigger screen
	if [ $pixels_a -gt $pixels_b ]
	then
		returned_res=$res_a
		return
	else
		returned_res=$res_b
		return
	fi

	# we don't need the out file anymore
	rm -rf $xlog
}

# lowers the resolution for a neat fit,
# tweak x_min and y_min for better screen adjustment...
fix_resolution ()
{
	local res=$returned_res

	local x_min=12
	local y_min=84

	local res_x=$(( `echo $res | awk -Fx '{print $1}'` - $x_min ))
	local res_y=$(( `echo $res | awk -Fx '{print $2}'` - $y_min ))
	fixed_res="$res_x"x"$res_y"
	return
}

update_flags ()
{
	servers=0
	for arg in $arguments
	do
		case "$arg" in
		-r)
			export flag_rdp=true
			;;
		-s)
			export flag_ssh=true
			;;
		-h)
			export flag_hlp=true
			;;
		-t)
			export flag_tst=true
			;;
		*)
			export SERVER=$arg
			servers=$(( servers + 1 ))
			;;
		esac
	done

	if [ $servers -gt 1 ]
	then
		export flag_msr=true
	fi
}

server_from_list ()
{
	dia_log=$TMP_DIR/dialog.log
	command=""
	name_len=${#name_array[@]}
	for (( i=0; i<$name_len; i++ ))
	do
		command+=`echo $i ${name_array[$i]}" "`
	done

	$DIALOG --clear \
	--title "Server Selection" \
	--menu "Select predefined server:" \
	11 30 $name_len $command 2> $dia_log

	retval=$?
	if $flag_rdp
	then
		if [ $retval != 0 ]
		then
			clear
			echo Cancelled
			rm $dia_log
			exit 1
		fi
	fi

	# adding 1 so final execution of rdesktop will be aligned
	# weather the script received an input server name or dialog was used.
	returned_index=$(( `cat $dia_log` + 1 ))
	return
	rm -rf $dia_log
}

print_exit ()
{
	printf "${error_message}\n"
	usage_text
	get_max_string_length
	usage_known $max_string_length
	exit $exit_code
}

#========================
#= END FUNCTIONS REGION =
#========================

#========================================================
#= START MAIN REGION                                    =
#= MAIN: the script is actually doing stuff from hereon =
#========================================================

# definition of flags, these are being overwritten per argument used:
# nsl=need search list; rdp=rdesktop; ssh=ssh; hlp=help; msr=multi-servers
flag_nsl=false
flag_rdp=false
flag_ssh=false
flag_hlp=false
flag_msr=false
flag_tst=false

update_flags $arguments

# "-h" anywhere will print the usage info
if $flag_hlp
then
	error_message="got -h"
	exit_code=0
	print_exit $error_message $exit_code
fi

# can't use both rdesktop and ssh...
if $flag_rdp && $flag_ssh
then
	error_message="Please use either SSH (-s) or rdesktop (-r)"
	exit_code=1
	print_exit $error_message $exit_code
fi

# An argument without a leading '-' is used as the SERVER to login to

# don't know what to do with more than 1 SERVER (SERVER is last argument used)
if $flag_msr
then
	error_message="Please use only one server as a variable"
	exit_code=1
	print_exit $error_message $exit_code
fi

# If there is no SERVER, show the known servers list from name_array
if [ "$SERVER" == "" ]
then
	server_from_list
fi

# If SERVER is provided, try search it in the host array
# this returns returned_index
if [[ $returned_index -eq "" ]]
then
	get_index $SERVER
fi

# if returned_index is empty, its because the argument is not in the array
# in this case COMMAND needs to look it up
if [[ $returned_index -eq "" ]]
then
	export flag_nsl=true
fi

# rdesktop will use the largest screen
# this returns returned_res
get_resolution

# lowering the resolution a little so the window decoration won't cut the screen
# this returns fixed_res
fix_resolution $returned_res

# building up login command using SSH or RDESKTOP
if $flag_rdp
then
	COMMAND=$RDESKTOP
	if $flag_nsl
	then
		ARGS="
		-r clipboard:CLIPBOARD \
		-g $fixed_res \
		$ret_local_folder \
		-r disk:local=$folder \
		$SERVER"
	else
		ARGS="
		-P -z -a 32 -x 0x81 \
		-T [${name_array[ (( $returned_index - 1 )) ]}]:[${ip_array[ (( $returned_index - 1 )) ]}] \
		-r clipboard:CLIPBOARD \
		-g $fixed_res \
		-u ${user_array[ (( $returned_index - 1 )) ]} \
		-p ${pass_array[ (( $returned_index - 1 )) ]} \
		-r disk:local=$folder \
		${ip_array[ (( $returned_index - 1 )) ]}"
	fi
else
	COMMAND=$SSH
	if $flag_nsl
	then
		read -e -p "Please insert a username: " -i "" USERNAME
		ARGS="$USERNAME@$SERVER"
	else
		PREARG="$SSHPASS -p '${pass_array[ (( $returned_index - 1)) ]}'"
		COMMAND="$PREARG $COMMAND"
		ARGS="${user_array[ (( $returned_index - 1 )) ]}@$SERVER"
	fi
fi

clear

# if we passed this point, we can execute:
EXE="$COMMAND $ARGS"
if $flag_tst
then
    $EXE | sed 's/         //g' &
else
echo    $EXE &
fi

sleep 3
printf "\n"

# cleaned just in case...
unset DIALOG
unset RDESKTOP
unset SERVER
unset XRANDR
unset arguments
unset dialog
unset flag_nsl
unset flag_rdp
unset flag_ssh
unset flag_hlp
unset folder
unset script_exe
unset max_string_length
#===================
#= END MAIN REGION =
#===================
