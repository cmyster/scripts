#!/bin/bash

# make sure we start at home.
cd /home/stack

# source stackrc
. stackrc

# to upload stuff later, we need sshpass
echo "making sure sshpass is installed"
yum install -y sshpass &> /dev/null

# definitions and facts
HOSTNAME=$(hostname)
BASE="http://127.0.0.1:5050/v1/introspection"
TOKEN=$(openstack token issue -f value -c id)
DEFAULT_NIC=$(route | grep default | awk '{print $NF}')
IP=$(ip address show $DEFAULT_NIC | grep -Po 'inet \K[\d.]+')

# parsing nova list to create arrays from
rm -rf /tmp/tmpnovalist
echo "getting nodes info from nova"
nova list | grep -v "Status\|---" | awk '{print $2" "$4}' &> /tmp/tmpnovalist
NUM=$(cat /tmp/tmpnovalist | wc -l)
if [ $NUM -eq 0 ]
then
    echo "nova list came up empty"
    exit 1
fi
NOVA_UUIDS=( $(cat /tmp/tmpnovalist | cut -d " " -f 1) )
NOVA_NAMES=( $(cat /tmp/tmpnovalist | cut -d " " -f 2) )

# build the ironic uuid array  in the order that nova list did
echo "getting nodes ironic UUIDs"
rm -rf /tmp/tmpnovashow
for (( index=0; index<${#NOVA_UUIDS[@]}; index++ ))
do
    nova show ${NOVA_UUIDS[$index]} \
        | tr -d "|" | grep hypervisor_hostname \
        | awk '{print $2}' >> /tmp/tmpnovashow
done
IRONIC_UUIDS=( $(cat /tmp/tmpnovashow) )

SAVE_DIR=${IP}-$(date +%s)
mkdir $SAVE_DIR
cd $SAVE_DIR

# getting the actual data and saving it to individual files
echo "getting provision data for each ironic node"
for (( index=0; index<${#IRONIC_UUIDS[@]}; index++ ))
do
    curl -s -H "X-Auth-Token: $TOKEN" \
    ${BASE}/${IRONIC_UUIDS[$index]}/data \
    | python -m json.tool &> /home/stack/$SAVE_DIR/${NOVA_NAMES[$index]}.log
done

# tarball it and send to ikook:
# http://ikook.tlv.redhat.com/uploads/introspection/<hostname>
echo "sending the data"
cd /home/stack
cp /var/lib/rhos-release/latest-installed $SAVE_DIR/version 2> /dev/null
tar cf $SAVE_DIR.tar.gz $SAVE_DIR
sshpass -p qum5net scp -o StrictHostKeyChecking=no $SAVE_DIR.tar.gz \
    rhos-qe@ikook.tlv.redhat.com:/home/rhos-qe/uploads/introspection
rm -rf ~/tmpnovalist ~/tmpnovashow ~/${SAVE_DIR}*
