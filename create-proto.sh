#!/bin/bash
virt-customize -q -a $GUEST_FILE --root-password password:$ROOT_PASS
virt-customize -q -a rhel-guest-image-latest.qcow2 --run-command 'yum remove cloud-init* NetworkManager* -y'
