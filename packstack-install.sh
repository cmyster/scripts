#!/bin/bash

### Don't forget to add the wanted repositories ###
### Go over the SETTINGS section, this is a destructive script...

# WARNING: This scripts comes as is and its working for me on my setup.
#          This scripts is expecting a clean system.
#          If something breaks, don't blame me.

### SETTINGS ###

# Direct download URL for the RDO RPM
RPM_URL="http://rhos-release.virt.bos.redhat.com/repos/rhos-release/rhos-release-latest.noarch.rpm"

# Setting the usage text
USAGE="usage : $0 [a single integer, the rhos release version. i.e. 4, 5...]"

# Setting to true here will delete all the repo files and create a new
# file with information given here.
DEL_REPOS=true

# Setting this to true will reboot the system if yum update finds that
# a new kernel was installed
REBOOT=true

# HOSTs configuration for the answer file. packstack generates
# configuration for a single machine from which it is being run, so if
# you are installing on a single machine, this list should be empty.
# this is an example of using this to install COMPUTE_HOSTS on 2 IPs:
# Available hosts settings:
# CONFIG_CONTROLLER_HOST
# CONFIG_COMPUTE_HOSTS
# CONFIG_NETWORK_HOSTS
# CONFIG_STORAGE_HOST
# CONFIG_AMQP_HOST
# CONFIG_MARIADB_HOST
# CONFIG_MONGODB_HOST
# CONFIG_REDIS_HOST
# Example:
# hosts_config=(
#               "COMPUTE_HOSTS" "10.1.2.2,10.1.2.3"
#              )

hosts_config=(
             )

# General changes: should fit something that sed can understand later.
# Example:
# general_changes=(
#                  "PASSWORD" "123456"
#                 )
# will be run later like so:
# sed -i 's/PASSWORD=.*/PASSWORD=123456/g' $ANS_FILE

general_changes=(
                 "_PW" "123456"
                 "PASSWORD" "123456"
                 "INSTALL" "y"
                 "NAGIOS_INSTALL" "n"
                 "CONFIG_DEBUG_MODE" "y"
                 "IRONIC_INSTALL" "n"
                 "ML2_TYPE_DRIVERS" "vlan"
                 "PROVISION_DEMO" "n"
                 "NEUTRON_ML2_VLAN_RANGES" "physnet1:182:182"
                 "BRIDGE_MAPPINGS" "physnet1:br-ex"
                 "TENANT_NETWORK_TYPES" "vlan"
                 "CINDER_VOLUMES_CREATE" "y"
                )

### SANITY ###

# Exit if not root
if [[ "$(whoami)" != "root" ]]
then
    echo "please run this script as root"
    exit 1
fi

# This script needs a single argument for the rhos release version
if [ $# -ne 1 ]
then
    echo $USAGE
    exit 1
fi

# The input should be a single integer
TEST='^[5-7]+$'
if ! [[ $1 =~ $TEST ]]
then
    echo $USAGE
    exit 1
else
    echo "setting rhos release to version $1"
    RELEASE=$1
fi

### FUNCTIONS ###

# Modify a file by a set of key=value rules with sed
conf_changer ()
{
    file="${1}"
    shift
    changes=("${@}")
    for index in $(seq 0 2 $(( ${#changes[@]} - 1 )))
    do
        param=${changes[$index]}
        value=${changes[$(( $index + 1 ))]}
        sed -i 's/'$param=.*'/'$param=$value'/g' $file
    done
}

clean_env ()
{
    yum remove -y epel-release &> /dev/null
    yum remove -y rhos-release &> /dev/null
    # Deleting yum's cache folder
    rm -rf /var/cache/yum/*
}

install_rhos ()
{
    yum install -y $RPM_URL &> /dev/null
    if [ $? -ne 0 ]
    then
        echo "yum was unable to install rhos-release"
        exit 1
    fi
}

del_kept_repos ()
{
    for file in ${CURRENT_REPOS[@]}
    do
        echo "deleting $file"
        rm -rf /etc/yum.repos.d/$file
    done
}

update_env ()
{
    UPDATE_LOG=/tmp/pack_install_update.log
    rm -rf $UPDATE_LOG
    yum update -y &> $UPDATE_LOG
    if [ $? -ne 0 ]
    then
        exit 1
    fi
}

check_kernel ()
{
    grep 'kernel-[0-9]\.' $UPDATE_LOG &> /dev/null
    if [ $? -eq 0 ]
    then
        echo "new kernel installed. rebooting now"
        echo "please re-run $0 after reboot"
        reboot
        exit 0
    else
        echo "no new kernel"
    fi
}

ins_packstack ()
{
    rpm -qa | grep packstack &> /dev/null
    if [ $? -ne 0 ]
    then
        yum install -y openstack-packstack &> /dev/null
    fi
}

set_answer_file ()
{
    ANS_FILE=$(hostname | cut -d . -f 1).answer
    if [ ! -f $ANS_FILE ]
    then
        packstack --gen-answer-file=$ANS_FILE
    fi
}

### MAIN ###

# 1.  Cleaning the environment
echo "cleaning the system"
clean_env

# 2.  If current repo files are to be deleted, keep a list of them now
# before installing the rhos-release repo because installing a package
# still needs valid repo files.
if $DEL_REPOS
then
    echo "caching repo files to be deleted later"
    CURRENT_REPOS=$(ls /etc/yum.repos.d)
fi

# 3.  Installing rhos-release
echo "installing rhos-release"
install_rhos

# 4.  If set to delete repos, do it now, this should keep only the repo file
# installed by installing rhos-release.
if $DEL_REPOS
then
    echo "deleting repo files"
    del_kept_repos
fi

# 5.  Running rhos-release. This takes care of setting the needed repos.
echo "setting rhos release to version $RELEASE"
rhos-release $RELEASE

# If there is a need to change anything in the repository files, do it now.
# Change the repos to use Boston instead of TLV.

# 6.  Updating the environemt
echo "updating the system"
update_env

# 7.  If true, the system will be rebooted if a new kernel was installed.
if $REBOOT
then
    echo "checking if a new kernel was installed"
    check_kernel
fi

# 8.  Installing packstack if its not already installed.
echo "Installing openstack-packstack"
ins_packstack

# 9.  Domains here are all called domainx.foo.bar. I like to use a shorter
# form of it for the answer file. Answer file is generated by packstack
echo "creating the answer file"
set_answer_file

# 10. Going over the lists of changes to be performed on the answer file
echo "making modifications to the answer file"
conf_changer "$ANS_FILE" "${hosts_config[@]}"
conf_changer "$ANS_FILE" "${general_changes[@]}"

# 11. Running packstack with the created answer file.
echo "running packstack"
packstack --answer-file=$ANS_FILE

# 12. Clearing used files
echo "deleting the log-file"
rm -rf $UPDATE_LOG

# 13. Disabling NetworkManager
systemctl disable NetworkManager &> /dev/null
systemctl stop NetworkManager &> /dev/null
