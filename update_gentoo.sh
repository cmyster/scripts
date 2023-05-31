#!/bin/bash
# set -e
#
### PARAMETERS
LOGDIR="/tmp/update"
TIME="$(date +%Hh%Mm%Ss)"
LOGFILE=$LOGDIR/update_"$TIME"_log
EMERGE="/usr/bin/emerge --color n --nospinner"
SECONDS=0
CONF_PATH="/home/augol/gdrive/config/config_kernel"

### SETUP
# Run only if root.
set -e
if [[ "$(whoami)" != "root" ]]; then
	/bin/echo "This script needs to be run as root."
	exit 1
fi

# Creating log dir.
if [ ! -d $LOGDIR ]; then
	mkdir -p $LOGDIR
fi

# Initializing log file.
/bin/echo "Started at $(date)" >"$LOGFILE"

### FUNCTIONS
function logger() {
	# This is the format used in the log file.
	/bin/echo -e "\n=== [$(date +%T)] $1\n" | tee -a "$LOGFILE"
}

function installed() {
	# Checking if a package is intalled or not.
	if emerge -s "$1\$" | grep "Not Installed" &>/dev/null; then
		return 1
	else
		return 0
	fi
}

function new_package() {
	# Check if there is a newer package.
	# Gets a package atom, returns an int bool.
	$EMERGE -s "$1" &>"$LOGDIR"/new_package
	INSTALLED=$(grep "installed" "$LOGDIR"/new_package | awk '{print $NF}')
	AVAILABLE=$(grep "available" "$LOGDIR"/new_package | awk '{print $NF}')
	rm -rf "$LOGDIR"/new_package
	if [[ "$INSTALLED" != "$AVAILABLE" ]]; then
		return 0
	else
		return 1
	fi
}

function emerging() {
	# Returns int bool if emerge is running.
	if /usr/bin/pgrep emerge &>/dev/null; then
		return 0
	else
		return 1
	fi
}

function update_kernel() {
	logger "Cleaning environemt before compiling a new kernel image."
	cd /usr/src/linux
	/usr/bin/make clean &>>"$LOGFILE"
	/usr/bin/make mrproper &>>"$LOGFILE"
	cp "$CONF_PATH" .config
	/usr/bin/make olddefconfig &>>"$LOGFILE"

	logger "Compiling a new kernel image."

	/usr/bin/make -j$(($(nproc) - 2)) 1>/dev/null
	/usr/bin/make modules_install
	rm -rf /boot/{config,System,vmlinuz}*-gentoo
	/usr/bin/make install

	chown augol:augol .config
	cp .config "$CONF_PATH"

	logger "Running GRUB"
	/usr/sbin/grub-mkconfig -o /boot/grub/grub.cfg

	logger "Rebuilding 3rd party modules."
	emerge @module-rebuild &>/dev/null

	logger "replacing it87 module with the one from frankcrawford/it87."
	git clone https://github.com/frankcrawford/it87
	cd it87
	# it87 want's to make sure that the GCC that was used for the 'running'
	# kernel is the same one as the one used as the default GCC installed.
	# If there was an updatre with both GCC and the kernel, it means that
	# the running kernel (which is not the latest) is compiled with an older
	# GCC version. We need to change the Makefile so it will grab the latest
	# kernel version from /usr/src/linux as this points to the latest kernel
	# at this stage, which is how we discover KERNEL_NEW earlier.
	sed -i 's,uname -r,file /usr/src/linux | cut -d "-" -f 2-,' Makefile
	make clean
	make
	find /usr/lib/modules -name it87.ko.gz -exec rm -f {} \;
	make install
	cd ..
	rm -rf it87

	# At this point we can assume that we have new and old kernel resources
	# installed, so we can remove the previous one as its not needed after
	# the next reboot
}

### FUNCTIONS END

### BEGIN

# Saving and parsing runtime arguments.

SYNC=false
UPDT=false
RBLD=false

case $@ in
-s)
	SYNC=true
	;;
-u)
	UPDT=true
	;;
-k)
	RBLD=true
	;;
-f)
	SYNC=true
	UPDT=true
	;;
*)
	printf "use %s -s to sync, -u to update, -k to rebuild the kernel,\n or -f to do all.\n" "$0"
	exit 0
	;;
esac

# On new installments, we might be missing a few packages...
for pkg in "app-portage/gentoolkit" "sys-boot/grub" "sys-apps/mlocate" "dev-vcs/git"
    do
    if ! installed "$pkg"; then
        logger "$pkg was not found on this system, installing it now."
        $EMERGE "$pkg"
    fi
done

# If this is a new system, gentoo-sources wants to have symlink USE
if ! installed "sys-kernel/gentoo-sources"; then
	echo "sys-kernel/gentoo-sources symlink" >/etc/portage/package.use/gentoo-sources
	$EMERGE "sys-kernel/gentoo-sources symlink"
fi

KERNEL_OLD="$(uname -r)"

if $SYNC; then
	# Synchronize, and print the last part of the proccess.
	logger "Synchronizing..."
	$EMERGE --sync &>>"$LOGFILE"
	tail "$LOGFILE"
	logger "DONE"
fi

if $RBLD; then
	KERNEL_NEW="$(file /usr/src/linux | cut -d "-" -f 2-)"
	printf "Building kernel version %s\n" "$KERNEL_NEW"
fi

if $UPDT; then
	# Making sure portage is up-to-date before emerging world.
	# Sometimes GenToolKit blocks compiling a new portage between versions,
	# sould be safe to oneshot before portage if there is a new version of it.
	# After that, oneshot portage.
	for pkg in "app-portage/gentoolkit" "sys-apps/portage"; do
		if new_package "$pkg"; then
			logger "New $pkg version $AVAILABLE is available. Installing..."
			$EMERGE --oneshot "$pkg" &>>"$LOGFILE"
			tail "$LOGFILE"
			logger "DONE"
		else
			logger "Installed $pkg version $INSTALLED is up-to-date."
		fi
	done
	logger "DONE"

	# To overwrite a new vimrc, check if there is a new vim now and overwrite
	# vimrc later.
	NEW_VIM=false
	if new_package "app-editors/vim$"; then
		export NEW_VIM=true
		if test -f "/etc/vim/vimrc"; then
			cp /etc/vim/vimrc /etc/vim/vimrc_backup
		fi
	fi

	# When compiling 3rd party modules, sometimes (it87) wants to make sure
	# that the kernel was built with the exact version of the currently used
	# compiler. If not, the kernel will have to be recompiled with the most
	# up-to-date compiler.
	NEW_COMPILER=false
	if new_package "sys-devel/gcc$"; then
		export NEW_COMPILER=true
	fi

	# Running emerge on @world twice takes time, but it prints everything there-
	# is to emerge in order which is nice for logging.
	logger "Refreshing system"
	$EMERGE --update --deep --changed-use --newuse --tree --ask --pretend @world
	$EMERGE --update --deep --changed-use --newuse --with-bdeps=y --keep-going --tree @world &>>"$LOGFILE" &

	while emerging; do
		BUILDING=$(grep "Emerging (" "$LOGFILE" | tail -n 1)
		if [[ "$BUILDING" != "$PREVIOUS" ]]; then
			PREVIOUS="$BUILDING"
			/bin/echo "$BUILDING"
		fi
		sleep 1
	done
	logger "DONE"

	logger "Testing if there is a need for a new kernel image."
	KERNEL_NEW="$(file /usr/src/linux | cut -d "-" -f 2-)"
	if [[ "$KERNEL_OLD" != "$KERNEL_NEW" ]]; then
		logger "Current kernel version: $KERNEL_OLD will be replaced by new kernel version $KERNEL_NEW"
		# we need to disable the NEW_COMPILER flag if we're going to compile the kernel anyway.
		export NEW_COMPILER=false
		update_kernel
		logger "New kernel ($KERNEL_NEW) replaced older version ($KERNEL_OLD). Please reboot."
	else
		logger "Current kernel version ($KERNEL_OLD) is up-to-date"
	fi

	if $NEW_COMPILER; then
		logger "New compiler means we need to recompiled the kernel."
		update_kernel
	fi

	logger "DONE"

	logger "Removing obsolete packages."
	$EMERGE --depclean
	logger "DONE"

	logger "Rebuilding preserved packages where needed."
	$EMERGE @preserved-rebuild &>>"$LOGFILE"
	logger "DONE"

	if $NEW_VIM; then
		cp /etc/vim/vimrc_backup /etc/vim/vimrc
		rm -rf /etc/vim/vimrc_backup
	fi

	logger "cleaning package and distfiles cache."
	eclean-pkg -d | tail -n 1
	eclean-dist -d | tail -n 1
fi

logger "refreshing locate DB"
updatedb

#Time calculations
TIME="$SECONDS"
H=0
M=0
S=0

if ((TIME > 3600)); then
	H=$((TIME / 3600))
	HS=$((H * 3600))
	TIME=$((TIME - HS))
fi

M=$((TIME / 60))
S=$((TIME % 60))

if [ $H -gt 0 ]; then
	logger "This script ran for $H hours, $M minuts and $S seconds."
else
	logger "This script ran for $M minuts and $S seconds."
fi

/bin/echo "Compressing $LOGFILE"
xz "$LOGFILE"
/bin/echo "Full log is in ${LOGFILE}.xz"
/bin/echo "DONE"
