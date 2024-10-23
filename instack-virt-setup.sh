#!/bin/bash

### SETTINGS ###
REBOOT_HOST=${REBOOT_HOST:-0}
UPDATE_LOG=/tmp/host_update
POODLE=${POODLE:-"-d"}
MIRROR="http://ikook.tlv.redhat.com"
RHEL7_IMAGE_URL="${MIRROR}/rhel-guest-image/7.1/20150224.0/images/rhel-guest-image-7.1-20150224.0.x86_64.qcow2"
PUDDLE_VERSION=${PUDDLE_VERSION:-"2015-07-30.1"}


### FUNCTIONS ###
set_rhos_release ()
{
    # Installes rhos-release package and repos.
    yum remove -y rhos-release
    rpm -ivh http://rhos-release.virt.bos.redhat.com/repos/rhos-release/rhos-release-latest.noarch.rpm
    rm -rf /etc/yum.repos.d/*
    rhos-release $POODLE 7-director
    yum-config-manager --enable rhelosp-rhel-7-server-opt
    yum update -y &> $UPDATE_LOG
    if $REBOOT_HOST
    then
        if grep 'kernel-[0-9]\.' $UPDATE_LOG &> /dev/null
        then
            echo "New kernel was installed. Rebooting host."
            reboot
        fi
    fi
}

set_x_stuff ()
{
    # If needed, install X related stuff from virt-manager
    yum install -y \
        instack-undercloud screen kvm virt-viewer virt-manager \
        libvirt libvirt-python python-virtinst xauth xorg-x11-xinit \
        xorg-x11-xinit-session liberation-* xorg-x11-server-Xorg \
        xclock xorg-x11-fonts* dejavu-* seabios-bin seabios \
        ipxe-bootimgs ipxe-roms ipxe-roms-qemu qemu-kvm

    touch ~/.Xauthority
    mcookie | sed -e 's/^/add :0 . /' | xauth -q
}

set_kvm_module ()
{
    # Sets the relevent kernel module
    case grep GenuineIntel /proc/cpuinfo &> /dev/null in:
        0)
            export INTEL=0
            ;;
        *)
            export INTEL=1
            ;;
    esac

    if $INTEL
    then
        if grep "N" /sys/module/kvm_intel/parameters/nested &> /dev/null
        then
            rmmod kvm-intel
            echo "options kvm-intel nested=y" >> /etc/modprobe.d/dist.conf
            modprobe kvm-intel
        fi
    else
        if grep "0" /sys/module/kvm_amd/parameters/nested &> /dev/null
        then
            rmmod kvm-amd
            echo "options amd nested=1" >> /etc/modprobe.d/dist.conf
            modprobe kvm-amd
        fi
    fi
}

set_stack_user ()
{
    useradd stack
    echo stack | passwd stack --stdin
    echo "stack ALL=(root) NOPASSWD:ALL" | tee -a /etc/sudoers.d/stack
    chmod 0440 /etc/sudoers.d/stack
}


su - stack

IMAGE="http://ikook.tlv.redhat.com/rhel-guest-image/7.1/20150224.0/images/rhel-guest-image-7.1-20150224.0.x86_64.qcow2"
curl -O $IMAGE

export DIB_LOCAL_IMAGE=`basename $IMAGE`
export
DIB_YUM_REPO_CONF="/etc/yum.repos.d/rhos-release-7-director-rhel-7.1.repo /etc/yum.repos.d/rhos-release-7-rhel-7.1.repo"

export NODE_DIST=rhel7
export NODE_COUNT=7
export NODE_MEM=3072
export NODE_CPU=2

export UNDERCLOUD_OS=rhel7
export UNDERCLOUD_NODE_MEM=8192
export UNDERCLOUD_NODE_CPU=3

#export TESTENV_ARGS="--baremetal-bridge-names 'brbm' --vlan-trunk-ids='10 20 30 40 50'"

instack-virt-setup

# at this point I add swap space and enable nested virtualization.
sudo virsh edit vms and add:

<cpu mode='host-passthrough'></cpu>

ssh root@<some IP>
su - stack
sudo rpm -ivh
http://rhos-release.virt.bos.redhat.com/repos/rhos-release/rhos-release-latest.noarch.rpm
sudo rhos-release 7-director
sudo yum update -y
sudo yum install -y python-rdomanager-oscplugin wget vim

openstack --debug --log-file=undercloud_install.log undercloud install

source stackrc

for file in overcloud-full.tar discovery-ramdisk.tar
    deploy-ramdisk-ironic.tar
do
    curl -O
    http://ikook.tlv.redhat.com/mburns/2015-07-30.1/images/$file
    tar xf $file
done

openstack overcloud image upload
openstack baremetal import --json instackenv.json
openstack baremetal configure boot
openstack baremetal introspection bulk start

openstack flavor create --id auto --ram 2048 --disk 40 --vcpus 1
baremetal
openstack flavor set --property "cpu_arch"="x86_64" --property
"capabilities:boot_option"="local" baremetal

SUBNET=$(neutron subnet-list | grep -v 'pools\|---' | cut -d" "-f 2)
neutron subnet-update $SUBNET --dns-nameserver 10.35.28.28
neutron subnet-show $SUBNET

# create a file called network-environment.yaml
#echo "parameter_defaults:
#  InternalApiNetCidr: 172.16.20.0/24
#  StorageNetCidr: 172.16.21.0/24
#  TenantNetCidr: 172.16.22.0/24
#  ExternalNetCidr: 172.16.23.0/24
#  InternalApiAllocationPools: [{'start': '172.16.20.10', 'end':
#  '172.16.20.99'}]
#  StorageAllocationPools: [{'start': '172.16.21.10', 'end':
#  '172.16.21.99'}]
#  TenantAllocationPools: [{'start': '172.16.22.10', 'end':
#  '172.16.22.99'}]
#  ExternalAllocationPools: [{'start': '172.16.23.10', 'end':
#  '172.16.23.99'}]
#  ExternalInterfaceDefaultRoute: 172.16.23.251" >
#  /home/stack/network-environment.yaml

#sudo ovs-vsctl add-port br-ctlplane vlan10 tag=10 -- set
interface vlan10 type=internal
#sudo ip l set dev vlan10 up
#sudo ip addr add 172.16.23.251/24 dev vlan10
#sudo iptables -A BOOTSTACK_MASQ -s 172.16.23.0/24 ! -d
172.16.23.0/24 -j MASQUERADE -t nat

PLAN_ID=$(openstack management plan list | grep -v 'uuid\|---' |
cut -d" " -f 2)
openstack overcloud deploy \
      --debug \
        --log-file=overcloud_deploy.log \
          --plan=$PLAN_ID
  --templates \
        --ceph-storage-scale 1 \
        #  -e
  #  /usr/share/openstack-tripleo-heat-templates/environments/net-single-nic-with-vlans.yaml
  #  \
      #  -e
  #  /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml
  #  \
 -e /home/stack/network-environment.yaml
