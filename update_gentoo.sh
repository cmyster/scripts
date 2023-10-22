#!/bin/bash
# set -x
#
### PARAMETERS
LOGDIR="/tmp/update"
TIME="$(date +%Hh%Mm%Ss)"
LOGFILE=$LOGDIR/update_"$TIME"_log
EMERGE="/usr/bin/emerge --color n --nospinner"
SECONDS=0
CONF_PATH="/home/augol/gdrive/config/config_kernel"
CP="$(which cp)"
GREP="$(which grep)"

### SETUP

# Run only if root.
set -e
if [[ "$(whoami)" != "root" ]]; then
	printf "%s\n" "This script needs to be run as root."
	exit 1
fi

# Creating log dir.
if [ ! -d $LOGDIR ]; then
	mkdir -p $LOGDIR
fi

# Initializing log file.
printf "Started at %s\n" "$(date)" >"$LOGFILE"

### FUNCTIONS

function logger() {
	# This is the format used in the log file.
	printf "[%s] %s\n" "$(date +%T)" "$1" | tee -a "$LOGFILE"
}

function installed() {
	# Checking if a package is installed.
	# Gets a package atom, returns an int bool.
	if emerge -s "$1\$" | $GREP "Not Installed" &>/dev/null; then
		return 1
	else
		return 0
	fi
}

function new_package() {
	# Check if there is a newer package.
	# Gets a package atom, returns an int bool.
	$EMERGE -s "$1" &>"$LOGDIR"/new_package
	INSTALLED=$($GREP "installed" "$LOGDIR"/new_package | awk '{print $NF}')
	AVAILABLE=$($GREP "available" "$LOGDIR"/new_package | awk '{print $NF}')
	export INSTALLED
	export AVAILABLE
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

function delete_old_kernels() {
	# If the argument came in empty, ignore and exit this function.
	if [ -z "$1" ]; then
		return 0
	fi

	cd /usr/src
	ls -1 | grep -v "$1" | xargs rm -rf
	cd /usr/lib/modules
	ls -1 | grep -v "$1" | xargs rm -rf
}

function new_portage() {
	for pkg in "app-portage/gentoolkit" "sys-apps/portage"; do
		if new_package "$pkg"; then
			logger "New $pkg version $AVAILABLE is available. Installing."
			$EMERGE --oneshot "$pkg" &>>"$LOGFILE"
			tail "$LOGFILE"
		else
			logger "Installed $pkg version $INSTALLED is up-to-date."
		fi
	done
}

function new_kernel() {
	if new_package "sys-kernel/gentoo-sources$"; then
		logger "New kernel version $AVAILABLE is available. Emerging it now."
		$EMERGE --oneshot "sys-kernel/gentoo-sources" &>>"$LOGFILE"
		# At this point we expect that the most up-to-date folder is tne new linux source,
		# so we can use ls's natural sorting to give us the very last (and latest) folder.
		rm -rf /usr/src/linux
		ln -s /usr/src/$(ls -1 /usr/src | grep linux | sort | tail -n 1) /usr/src/linux
	fi
}

function new_compiler() {
	# Looking only for clang here because if it has newer version, the entire toolchain was updated.
	# If lld is not in 'world' then after we clean the environment, it gets removed.
	# If lld is in 'world' but we update only clang, emerge does not pick up lld's new version and
	# creates a blocking update conflict.
	# The solution here is to emerge both, so both are in 'world' and emerge would pick the entire chain,
	# and nothing is removed at the end when cleaning up.
	NEW_COMPILER=false
	if new_package "sys-devel/clang$"; then
		# If we hadn't complied the kernel, this flag tells us we need to.
		export NEW_COMPILER=true
		logger "New clang version $AVAILABLE is available. Installing the new build chain first."
		$EMERGE "sys-devel/clang" "sys-devel/lld" &>>"$LOGFILE"
	else
		logger "Current clang version $INSTALLED is up-to-date."
	fi
}

function build_kernel() {
	logger "Cleaning environment before compiling a new kernel image."
	cd /usr/src/linux
	/usr/bin/make clean &>>"$LOGFILE"
	/usr/bin/make mrproper &>>"$LOGFILE"
	"$CP" "$CONF_PATH" .config
	/usr/bin/make LLVM=1 LLVM_IAS=1 KCFLAGS="-O3 -march=native" olddefconfig &>>"$LOGFILE"

	logger "Compiling and installing a new kernel image."

	/usr/bin/make -j$(($(nproc) - 2)) LLVM=1 LLVM_IAS=1 KCFLAGS="-O3 -march=native" 1>/dev/null
	/usr/bin/make modules_install 1>/dev/null
	rm -rf /boot/{vmlinuz,System.map,config}
	/usr/bin/make install &>/dev/null
	$CP -f .config /boot/config

	$CP .config "$CONF_PATH"

	logger "Rebuilding 3rd party modules."
	emerge @module-rebuild &>/dev/null

	# At this point we can assume that we have new and old kernel resources installed,
	# so we can remove the previous ones as they're not needed after the next reboot.

	delete_old_kernels "$(head /boot/config | grep "Kernel Configuration" | awk '{print $3}')"

	# Lasly, we want to make sure that the 'linux' symlink is pointing to the correct folder.
	# This can happen sometimes if there was an issue.
	if ! readlink /usr/src/linux &>/dev/null; then
		ln -s /usr/src/$(ls -1 /usr/src | grep linux | sort | tail -n 1) /usr/src/linux
	fi
}

function should_build_kernel() {
	KERNEL_RUNNING="$(uname -r | cut -d "-" -f 1)"
	KERNEL_COMPILED="$(head /boot/config | grep "Kernel Configuration" | cut -d "-" -f 1 | cut -d " " -f 3)"
	KERNEL_AVAILABLE="$(emerge -s sys-kernel/gentoo-source | grep "Latest version available" | awk '{print $NF}')"
	KERNEL_EMERGED="$(emerge -s sys-kernel/gentoo-source | grep "Latest version installed" | awk '{print $NF}')"

	if [[ "$KERNEL_RUNNING" == "$KERNEL_COMPILED" ]]; then
		logger "Current running kernel $KERNEL_RUNNING is the same as the compiled kernel $KERNEL_COMPILED."
	fi

	if [[ "$KERNEL_RUNNING" != "$KERNEL_COMPILED" ]]; then
		logger "The loaded kernel ($KERNEL_RUNNING) and the compiled one ($KERNEL_COMPILED) are not the same!"
	fi

	if [[ "$KERNEL_EMERGED" != "$KERNEL_AVAILABLE" ]]; then
		logger "Current kernel $KERNEL_EMERGED will be replaced by $KERNEL_AVAILABLE"
		build_kernel
		return 0
	fi

	if [[ "$KERNEL_COMPILED" != "$KERNEL_AVAILABLE" ]]; then
		logger "Current kernel $KERNEL_COMPILED will be replaced by $KERNEL_AVAILABLE"
		build_kernel
		return 0
	fi

	if $NEW_COMPILER; then
		logger "New compiler installed, rebuilding the kernel"
		build_kernel
		return 0
	fi
}

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
	printf "use %s -s to sync, -u to update, -k to rebuild an existing kernel,\n or -f to do all.\n" "$0"
	exit 0
	;;
esac

# Making sure that the profile is loaded, which is crucial for instance in a chrooted environment.
. /etc/profile

# On new installments, we might be missing a few packages...
# First, we need to make sure that we have a working repo tree
if [ ! -d /var/db/repos/gentoo/sys-kernel/gentoo-sources ]; then
	logger "The gentoo/sys-kernel/gentoo-sources folder is missing. Did you forget to do emerge-webrsync?"
	exit 1
fi

for pkg in "app-portage/gentoolkit" "sys-apps/mlocate" "dev-vcs/git" "sys-kernel/gentoo-sources"; do
	if ! installed "$pkg"; then
		logger "$pkg was not found on this system, installing it now."
		$EMERGE "$pkg"
	fi
done

# If this is a new system, /usr/src/linux needs to point to the correct folder
if [ ! -L /usr/src/linux ]; then
	ln -s "$(ls -1 /usr/src | grep linux | sort | tail -n 1)" "/usr/src/linux"
fi

if $SYNC; then
	# Synchronize, and print the last part of the process.
	logger "Synchronizing..."
	$EMERGE --sync &>>"$LOGFILE"
	tail "$LOGFILE"
	logger "DONE"
fi

if $RBLD; then
	KERNEL="$(file /usr/src/linux | cut -d "-" -f 2-)"
	logger "Building kernel version $KERNEL"
	build_kernel
	exit 0
fi

if $UPDT; then
	# Making sure portage is up-to-date before emerging world.
	# Sometimes GenToolKit blocks compiling a new portage between versions.
	# It should be safe to oneshot it before portage if there is a new version.
	# After that, oneshot portage.
	new_portage

	# The following steps will make sure that prior to updating @world, the compiler and kernel are the most up-to-date:

	# 1. If there is a new compiler, we start from it.
	new_compiler

	# 2. If there is a new kernel version, we want to get it regardless if there was a new compiler or not.
	new_kernel

	# 3. At this point if we might have a new compiler or a new kernel so we need to consider if we should build the kernel:
	#   a. The loaded kernel and the compiled kernel are the same version, meaning there were no updates, no need to build.
	#   b. The loaded kernel is different from the compiled kernel. Since we always load the compiled kernel during boot,
	#      it means that the compiled kernel is newer than the one loaded, and we did not reboot since we compiled it, so no
	#      need to build, and a reboot will take care of this difference.
	#   c. The emerged and the available kernels differ, so we need to build the new available kernel.
	#   d. If @world update replaced the kernel in /usr/src/linux but for some reason the compiled kernel differs when we run
	#      this script, it means that we skipped build_kernel and we want to do it now.
	#   e. If there was a new compiler, we need to build the kernel regardless if there was a new kernel or not.
	should_build_kernel

	### EMERGE UPDATE @WORLD

	# Running emerge update @world twice takes time, but it prints everything to build in order, which is nice for logging.
	logger "Refreshing @world"
	$EMERGE --update --deep --changed-use --newuse --tree --ask --pretend @world
	$EMERGE --update --deep --changed-use --newuse --with-bdeps=y --keep-going --tree --backtrack=15 @world &>>"$LOGFILE" &

	while emerging; do
		BUILDING=$($GREP "Emerging (" "$LOGFILE" | tail -n 1)
		if [[ "$BUILDING" != "$PREVIOUS" ]]; then
			PREVIOUS="$BUILDING"
			printf "%s\n" "$BUILDING"
		fi
		# I never saw emerge taking less than a few seconds between packages so 2 seconds is a safe bet.
		sleep 2
	done

	logger "Removing obsolete packages."
	$EMERGE --depclean

	logger "Rebuilding preserved packages where needed."
	$EMERGE @preserved-rebuild &>>"$LOGFILE"

	logger "Cleaning package and distfiles cache."
	eclean-pkg -d | tail -n 1
	eclean-dist -d | tail -n 1
fi

logger "Refreshing locate DB"
updatedb

# Time calculations
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
	logger "This script ran for $H hours, $M minuets and $S seconds."
else
	logger "This script ran for $M minuets and $S seconds."
fi

logger "Compressing $LOGFILE"
xz "$LOGFILE"
# At this point logger is done so I need to printf the last few lines.
printf "Full log is in %s.xz\n" "${LOGFILE}.xz"
printf "%s\n" "DONE"
