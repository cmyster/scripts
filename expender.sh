#!/bin/bash

if [[ "$(whoami)" != "root" ]]
then
    echo "Please run $0 as root."
    exit 1
fi

WRK_DIR=/tmp/expending
CWD=$(pwd)
HELP_TXT="
This script uses ldd to scan files and search for missing libraries.\n
If any missing libraries are found, slackpkg file-search is used to install\n
the missing library. Note that some packages provide the same files.\n\n
   Usage:\n
   $0 -f <file>, where file is an executable or a library.\n
   $0 -d <directory>, all files in that directory will be analyzed.\n
   $0 -s, will go over all files in predefined directories.\n\n
Examples:\n
   $0 -f libxcb or gcc or kde.*\n
   $0 -d /usr/bin\n
   $0 -s\n"
show_help ()
{
    echo -e $HELP_TXT
    exit 0
}

if [ $# -gt 2 ]
then
    show_help
fi

case $1 in
    "-s") FULL_SEARCH=true ;;
    "-d") DIR_SEARCH=true ;;
    "-f") SINGLE=true ;;
       *) show_help ;;
esac

clean ()
{
    rm -rf $WRK_DIR
}

stop_here ()
{
    if [ ! -r $1 ]
    then
        echo "Stoping at this step, no need to continue."
        clean
        exit 0
    fi
}

rotateCursor()
{
    case $toggle
    in
        1)
        echo -n $1" |#---------| "$2
        echo -ne "\r"
        toggle="2"
        ;;
        2)
        echo -n $1" |-#--------| "$2
        echo -ne "\r"
        toggle="3"
        ;;
        3)
        echo -n $1" |--#-------| "$2
        echo -ne "\r"
        toggle="4"
        ;;
        4)
        echo -n $1" |---#------| "$2
        echo -ne "\r"
        toggle="5"
        ;;
        5)
        echo -n $1" |----#-----| "$2
        echo -ne "\r"
        toggle="6"
        ;;
        6)
        echo -n $1" |-----#----| "$2
        echo -ne "\r"
        toggle="7"
        ;;
        7)
        echo -n $1" |------#---| "$2
        echo -ne "\r"
        toggle="8"
        ;;
        8)
        echo -n $1" |-------#--| "$2
        echo -ne "\r"
        toggle="9"
        ;;
        9)
        echo -n $1" |--------#-| "$2
        echo -ne "\r"
        toggle="10"
        ;;
        10)
        echo -n $1" |---------#| "$2
        echo -ne "\r"
        toggle="11"
        ;;
        11)
        echo -n $1" |--------#-| "$2
        echo -ne "\r"
        toggle="12"
        ;;
        12)
        echo -n $1" |-------#--| "$2
        echo -ne "\r"
        toggle="13"
        ;;
        13)
        echo -n $1" |------#---| "$2
        echo -ne "\r"
        toggle="14"
        ;;
        14)
        echo -n $1" |-----#----| "$2
        echo -ne "\r"
        toggle="15"
        ;;
        15)
        echo -n $1" |----#-----| "$2
        echo -ne "\r"
        toggle="16"
        ;;
        16)
        echo -n $1" |---#------| "$2
        echo -ne "\r"
        toggle="17"
        ;;
        17)
        echo -n $1" |--#-------| "$2
        echo -ne "\r"
        toggle="18"
        ;;
        18)
        echo -n $1" |-#--------| "$2
        echo -ne "\r"
        toggle="1"
        ;;
        *)
        echo -n $1" |#---------| "$2
        echo -ne "\r"
        toggle="2"
        ;;
    esac
}

echo "Updating locate db."
updatedb
clean
mkdir -p $WRK_DIR
cd $WRK_DIR

SECONDS=0

if [ $SINGLE ]
then
    echo "Investigating $2"
    locate -r ${2}$ >> file-list
fi

if [ $DIR_SEARCH ]
then
    echo "Listing files in $2"
    if [ ! -d $2 ]
    then
        echo "Missing directory."
        exit 1
    fi
    find $2 -mindepth 1 -type f | sort | uniq > file-list
fi

if [ $FULL_SEARCH ]
then
    DIRS=(
          /bin
          /sbin
          /usr/bin
          /usr/sbin
          /usr/share
          /usr/games
          /usr/lib
          /usr/lib64
          /usr/libexec
          /lib64
         )

    for dir in ${DIRS[@]}
    do
        echo "Listing files in $dir"
        find $dir -mindepth 1 -type f | sort | uniq >> file-list
    done
fi

stop_here file-list

LINES=$(cat file-list | wc -l)
echo "Number of files to go over: $LINES"
# yey magic numbers
if [ $LINES -gt 20 ]
then
    DIV=$(( $LINES / 20 ))
    s=$(( $LINES / $DIV ))
else
    s=1
fi
rotateCursor "Working: " "0%"
i=1
for file in $(cat file-list)
do
    mod=$(( $i % $s ))
    case $mod in
        0)
        export p=$(( $i * 100 / $LINES ))
        rotateCursor "Working: " "${p}%"
        ;;
    esac
    echo "### $file ###" >> ldd-proto
    ldd "$file" 2> /dev/null | grep -i "not found" >> ldd-proto
    i=$(( i + 1 ))
done

rotateCursor "Working: " "100%"
echo ""
echo "Done."

stop_here ldd-proto

echo "Formating the ldd output ($(pwd)/ldd-out)."
grep -B 1 -i "not found" ldd-proto | grep -v "\-\-" | uniq > ldd-out

stop_here ldd-out

echo "Creating a list of packages whos files have missing dependencies ($(pwd)/needy-list)."
grep "###" ldd-out | cut -d " " -f 2 | sort | uniq | sed "s|^/||g" > requester-list
LINES=$(cat requester-list | wc -l)
echo "Number of files to go over: $LINES"
# yey magic numbers
if [ $LINES -gt 20 ]
then
    DIV=$(( $LINES / 20 ))
    s=$(( $LINES / $DIV ))
else
    s=1
fi
rotateCursor "Working: " "0%"
i=1
for file in $(cat requester-list)
do
    mod=$(( $i % $s ))
    case $mod in
        0)
        export p=$(( $i * 100 / $LINES ))
        rotateCursor "Working: " "${p}%"
        ;;
    esac
    slackpkg file-search $file | grep install | awk '{print $NF}' >> needy-proto
    i=$(( i + 1 ))
done

rotateCursor "Working: " "100%"
echo ""
echo "Done."

stop_here needy-proto

sort needy-proto 2> /dev/null | uniq > needy-list

echo "Creating a list of missing libraries ($(pwd)/lib-list)"
grep -i "not found" ldd-out | awk '{print $1}' | sort | uniq > lib-list

echo "Generating package list ($(pwd)/package-list)."
for lib in $(cat lib-list)
do
    slackpkg file-search "$lib " 2> /dev/null | grep uninstalled | awk '{print $NF}' | sort | uniq >> package-proto
done
sort package-proto | uniq > package-list

stop_here package-list

# The reason I do this check on package-list and not on lib-list is because
# ldd always finds missing files but the providing packages might not come
# from Slackware.

TOTAL_RUN="$(( $SECONDS / 60 )) minuts and $(( $SECONDS % 60 )) seconds"
if [ $(cat package-list | wc -l) -eq 0 ]
then
    echo "No missing packages."
else
    cat package-list | xargs slackpkg install
fi

echo "Searching missing packages took: $TOTAL_RUN."
cd $CWD
