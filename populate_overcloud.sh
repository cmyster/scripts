#!/bin/bash

CWD=$(pwd)
OPS="openstack"
LOG="population"

# Messages
CRC="Creating"
CRF="failed to be created!"
CRS="created successfully"

# Domain, project, user and role.
DOMAIN="test-domain"
PROJECT="test-project"
USER="test-user"
PASSWORD="12345678"
ROLE="test-role"

# Flavor
FLAVOR="test-flavor"
RAM=2048
DISK=8
SWAP=512
VCPU=2

# Network
NETWORK="test-network"
SUBNET="test-subnet"
CIDR_BASE="192.168.100"
CIDR="${CIDR_BASE}.0/24"
ROUTER="test-router"
PORT="test-port"

# Image
IMAGE_URL="http://ikook.tlv.redhat.com/gen_images/cloud/Fedora-Cloud-Base-29-1.2.x86_64.qcow2"
IMAGE_FILE=$(basename $IMAGE_URL)
IMAGE_NAME="test-f29"

# Load balancer
LB="test-lb"
LISTEN="test-listener"
POOL="test-pool"
HEALTH="test-health-monitor"
MEMBER="test-member"

cd /home/stack || exit 1
. overcloudrc.v3
rm -rf $LOG

# Domain
function domain ()
{
    echo "$CRC $DOMAIN"
    if ! $OPS domain list -f value | grep "$DOMAIN" &> /dev/null
    then
        $OPS domain create "$DOMAIN" &>> $LOG
    fi

    if ! $OPS domain list -f value | grep "$DOMAIN" &> /dev/null
    then
        echo "$DOMAIN $CRF"
        exit 1
    else
        echo "$DOMAIN $CRS"
    fi
}

# Project
function project ()
{
    echo "Creating $PROJECT"
    if ! $OPS project list -f value | grep "$PROJECT" &> /dev/null
    then
        $OPS project create "$PROJECT" \
            --domain "$DOMAIN" &>> $LOG
    fi

    if ! $OPS project list -f value | grep "$PROJECT" &> /dev/null
    then
        echo "$PROJECT $CRF"
        exit 1
    else
        echo "$PROJECT $CRS"
    fi
}

# User
function user ()
{
    echo "$CRC $USER"
    if ! $OPS user list | grep "$USER" &> /dev/null
    then
        $OPS user create "$USER" \
            --password "$PASSWORD" \
            --project "$PROJECT" &>> $LOG
    fi

    if ! $OPS user list | grep "$USER" &> /dev/null
    then
        echo "$USER $CRF"
        exit 1
    else
        echo "$USER $CRS"
    fi
}

# Role
function role ()
{
    echo "$CRC $ROLE"
    if ! $OPS role list -f value | grep "$ROLE" &> /dev/null
    then
        $OPS role create "$ROLE" &>> $LOG
        echo "Adding $USER to $ROLE"
        $OPS role add "$ROLE" \
            --user "$USER" \
            --project "$PROJECT" &>> $LOG
    fi

    if ! $OPS role list -f value | grep "$ROLE" &> /dev/null
    then
        echo "$ROLE $CRF"
        exit 1
    else
        echo "$ROLE $CRS"
    fi
}

# Flavor
function flavor ()
{
    echo "$CRC $FLAVOR"
    if ! $OPS flavor list -f value | grep "$FLAVOR" &> /dev/null
    then
        $OPS flavor create "$FLAVOR" \
            --ram $RAM \
            --disk $DISK \
            --swap $SWAP \
            --vcpus $VCPU \
            --public &>> $LOG
    fi

    if ! $OPS flavor list -f value | grep "$FLAVOR" &> /dev/null
    then
        echo "$FLAVOR $CRF"
        exit 1
    else
        echo "$FLAVOR $CRS"
    fi
}

# Network
function network ()
{
    echo "$CRC $NETWORK"
    if ! $OPS network list | grep "$NETWORK" &> /dev/null
    then
        $OPS network create "$NETWORK" --external &>> $LOG
    fi

    if ! $OPS network list | grep "$NETWORK" &> /dev/null
    then
        echo "$NETWORK $CRF"
        exit 1
    else
        echo "$NETWORK $CRS"
    fi
}

# Subnet
function subnet ()
{
    echo "$CRC $SUBNET"
    if ! $OPS subnet list | grep "$SUBNET" &> /dev/null
    then
        $OPS subnet create "$SUBNET" \
            --network "$NETWORK" \
            --subnet-range "$CIDR" &>> $LOG
    fi

    if ! $OPS subnet list | grep "$SUBNET" &> /dev/null
    then
        echo "$SUBNET $CRF"
        exit 1
    else
        echo "$SUBNET $CRS"
    fi
}

# Router
function router ()
{
    if ! $OPS router list | grep "$ROUTER" &> /dev/null
    then
        echo "$CRC $ROUTER"
        $OPS router create "$ROUTER" &>> $LOG
        echo "Setting $ROUTER to use $NETWORK as the external gateway"
        $OPS router set "$ROUTER" --external-gateway "$NETWORK" &>> $LOG
        echo "Adding $SUBNET to $ROUTER"
        $OPS router add subnet "$ROUTER" "$SUBNET" &>> $LOG
    fi

    if ! $OPS router list | grep "$ROUTER" &> /dev/null
    then
        echo "$ROUTER $CRF"
        exit 1
    else
        echo "$ROUTER $CRS"
    fi
}

# Ports
function ports ()
{
    for n in "10" "20" "30"
    do
        if ! $OPS port list | grep ${PORT}-${n} &> /dev/null
        then
            echo "$CRC ${PORT}-${n}"
            $OPS port create ${PORT}-${n} \
                --network "$NETWORK" \
                --fixed-ip \
                subnet=$SUBNET,ip-address=${CIDR_BASE}.${n} &>> $LOG
        fi

        if ! $OPS port list | grep ${PORT}-${n} &> /dev/null
        then
            echo "${PORT}-${n} $CRF"
            exit 1
        else
            echo "${PORT}-${n} $CRS"
        fi
    done
}

# Glance image
function image ()
{
    if ! $OPS image list | grep "$IMAGE_NAME" &> /dev/null
    then
        echo "$CRC $IMAGE_NAME"
        wget -q $IMAGE_URL
        $OPS image create "$IMAGE_NAME" \
            --disk-format qcow2 \
            --container-format bare \
            --file ${CWD}/${IMAGE_FILE} &>> $LOG

        rm -rf "$IMAGE_FILE"
    fi

    if ! $OPS image list | grep "$IMAGE_NAME" &> /dev/null
    then
        echo "$IMAGE_NAME $CRF"
        exit 1
    else
        echo "$IMAGE_NAME $CRS"
    fi
}

# Load Balancer
function amphora_online ()
{
    if openstack loadbalancer show "$LB" \
        | grep provisioning_status.*ACTIVE &> /dev/null \
        & openstack loadbalancer show "$LB" \
        | grep operating_status.*ONLINE &> /dev/null
    then
        return 0
    else
        return 1
    fi
}

function balance ()
{
    if ! $OPS loadbalancer list | grep "$LB" &> /dev/null
    then
        echo "$CRC $LB"
        $OPS loadbalancer create --name "$LB" \
            --vip-subnet-id $SUBNET &>> $LOG
    fi

    echo "Waiting for Amphora image to become available."
    for (( i=1; i<20; i++ ))
    do
        if amphora_online
        then
            echo "Amphora image came online."
            break
        fi
        sleep 10
    done

    if ! amphora_online
    then
        echo "Amphora image did not come online!"
        exit 1
    fi

    if ! $OPS loadbalancer list | grep "$LB" &> /dev/null
    then
        echo "$LB $CRF"
        exit 1
    else
        echo "$LB $CRS"
    fi
}

# LB Listener
function listener ()
{
    if ! $OPS loadbalancer listener list | grep "$LISTEN" &> /dev/null 
    then
        echo "$CRC $LISTEN"
        $OPS loadbalancer listener create --name "$LISTEN" \
            --protocol HTTP \
            --protocol-port 80 \
            $LB &>> $LOG
    fi
    if ! $OPS loadbalancer listener list | grep "$LISTEN" &> /dev/null 
    then
        echo "$LISTEN $CRF"
        exit 1
    else
        echo "$LISTEN $CRS"
    fi
}

# LB Pool
function pool ()
{
    if ! $OPS loadbalancer pool list | grep "$POOL" &> /dev/null
    then
        echo "$CRC $POOL"
        $OPS loadbalancer pool create --name "$POOL" \
            --lb-algorithm ROUND_ROBIN \
            --listener "$LISTEN" \
            --protocol HTTP &>> $LOG
    fi

    if ! $OPS loadbalancer pool list | grep "$POOL" &> /dev/null
    then
        echo "$POOL $CRF"
        exit 1
    else
        echo "$POOL $CRS"
    fi
}

# Health check
function health ()
{
    if ! $OPS loadbalancer healthmonitor list | grep "$HEALTH" &> /dev/null
    then
        echo "$CRC $HEALTH"
        $OPS loadbalancer healthmonitor create --name "$HEALTH" \
            --delay 5 \
            --max-retries 4 \
            --timeout 10 \
            --type HTTP \
            --url-path /healthcheck \
            "$POOL" &>> $LOG
    fi

    if ! $OPS loadbalancer healthmonitor list | grep "$HEALTH" &> /dev/null
    then
        echo "$HEALTH $CRF"
        exit 1
    else
        echo "$HEALTH $CRS"
    fi
}

# LB Member
function member ()
{
    for i in "10" "20"
    do
        if ! $OPS loadbalancer member list "$POOL" | grep ${MEMBER}-${i} &> /dev/null
        then
            echo "$CRC ${MEMBER}-${i}"
            $OPS loadbalancer member create --name ${MEMBER}-${i} \
                --subnet-id $SUBNET \
                --address ${CIDR_BASE}.${i} \
                --protocol-port 80 \
                $POOL &>> $LOG
        fi

        if ! $OPS loadbalancer member list "$POOL" | grep ${MEMBER}-${i} &> /dev/null
        then
            echo "${MEMBER}-${i} $CRF"
            exit 1
        else
            echo "${MEMBER}-${i} $CRS"
        fi
    done
}

# Floating IP
function fip ()
{
    echo "$CRC floating IP"
    VIP_PORT_ID=$($OPS loadbalancer show $LB -f value -c vip_port_id)
    FIP_ID=$($OPS floating ip create -f value -c id $NETWORK) 
    if ! $OPS floating ip list | grep $FIP_ID &> /dev/null
    then
        echo "floating IP $CRF"
        exit 1
    else
        echo "floating IP $CRS"
    fi

    echo "Attaching load balancer"
    $OPS floating ip set --port $VIP_PORT_ID $FIP_ID
}

# domain
# project
# user
# role
# flavor
# network
# subnet
# router
# ports
# image
# balance 
# listener
# pool
# health
# member
# fip
$1
