#!/bin/bash

if ! mount | grep "RHOS_infra"
then
    mount /opt/nfs/RHOS_infra
fi
