#!/bin/bash

# This script is meant to add SWAP area to OpenStack nodes (VMs) that
# were created with instack-virt-setup (those have a disc bus
# type=sata). Running this script only creates the device itself, as a
# 2nd deive (so boot order is not affected in any way).
# once you have a working OS on a node (VM), log into it and mount the
# SWAP are with these commands as root:
#
# mkswap /dev/sdb
# swapon /dev/sdb
# echo "/dev/sdb   swap   swap   defaults   0 0" >> /etc/fstab
#
# This script also changes the CPU type to host-passthrough to allow
# nested virtualization.

# This is the disk size that will be created for SWAP area.
SWAP_SIZE=${SWAP_SIZE-8}

# Only run this script as root.
if [[ "$USER" != "root" ]]
then
    echo "only root can run this script."
    exit 1
fi

function IS_RUNNING ()
{
    virsh domstate $1 | grep running &> /dev/null
    return $?
}

# This is later being written into each VM with virsh edit to change the
# CPU type into host-passthrough. This only takes effect after you power
# on the VM.
echo "<cpu mode='host-passthrough'></cpu>" > /tmp/add-cpu-passthrough

# Here we create a temp' XML to define the disk plus an actual virtual
# hard disk device to hold SWAP. Later virsh can use attach-device to
# connect it to the VM. This can only take place while the VM is powered
# down.
for VM in $(virsh list --all | grep -v "Name\|---" | sed '/^$/d' | awk '{print $2}')
do
    qcow_file=/var/lib/libvirt/images/${VM}_swap.qcow2
    echo "<disk type='file' device='disk'>
  <driver name='qemu' type='qcow2'/>
  <source file='/var/lib/libvirt/images/${VM}.qcow2'/>
  <target dev='sdb' bus='sata'/>
  <address type='drive' controller='0' bus='0' target='0' unit='1'/>
</disk>" > ~/${VM}_swap.xml
    rm -f $qcow_file
    if IS_RUNNING $VM
    then
        echo "${VM} is in running state and cannot have a disc attached to it.
Please run this script while the VM is offline."
    else
        qemu-img create -f qcow2 $qcow_file $SWAP_SIZE
        virsh attach-device --persistent $VM ~/${VM}_swap.xml
        rm -rf ~/${VM}_swap.xml
        virsh edit $VM &>/dev/null <<EOF

:6
:r /tmp/add-cpu-passthrough
:wq
EOF
    fi
done

