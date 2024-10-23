LOG=/var/www/htdocs/size.txt

PATH_ARRAY=( "/home/ftp/pub/Linux/Slackware" "/home/ftp/auto" "/home/ftp/cfme" "/home/ftp/gen_images" "/home/augol/mirror/puddle-images" "/home/ftp/images/rpms" "/home/rhos-qe" "/opt/nfs" )

echo "Capacity as of $(date)" > $LOG
echo "" >> $LOG

set -x
for TEST_PATH in ${PATH_ARRAY[@]}
do
    FIRST="$(echo /opt/nfs/RHOS_infra | cut -d "/" -f 2)"
    TOTAL=$(df -m $FIRST | tail -n 1 | awk '{print $2}')
    PATH_SIZE=$(du -m -c $TEST_PATH | tail -n 1 | awk '{print $1}')
    PERCENT=$(calc -d $PATH_SIZE*100/$TOTAL | awk -F. '{print $1}' | sed 's/\t//g')
    SPACES=""

    for SPACE in $(seq 1 $(( 35 - ${#TEST_PATH} )))
    do
        SPACES=$SPACES" "
    done

    echo -e "\t$TEST_PATH ${SPACES}${PATH_SIZE} MB  \t${PERCENT}%" >> $LOG
done
