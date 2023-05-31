#!/bin/bash
# Docs URL http://docs.xfce.org/xfce/building
SRC_URL="https://github.com/xfce-mirror"
TMP=/tmp/build_xfce4
PKGS="$TMP"/packages
PACKAGES=/var/log/packages
SLKCFLAGS="-O3 -fPIC -ffast-math -march=native"
XFCE="xfce4-dev-tools libxfce4util xfconf libxfce4ui garcon exo xfce4-panel tumbler thunar xfce4-settings xfce4-session xfwm4 xfdesktop xfce4-appfinder thunar-volman xfce4-power-manager parole xfce4-pulseaudio-plugin xfce4-notifyd xfce4-screenshooter xfce4-taskmanager xfce4-volumed-pulse xfce4-systemload-plugin xfce4-clipman-plugin xfce4-weather-plugin xfce4-xkb-plugin thunar-media-tags-plugin xfce4-sensors-plugin xfce4-mount-plugin xfce4-diskperf-plugin" 
## comes with Slackware:
WITH_SLACK="Thunar exo garcon gtk-xfce-engine libxfce4ui libxfce4util orage xfwm4 thunar-volman tumbler xfce4-appfinder xfce4-clipman-plugin xfce4-dev-tools xfce4-notifyd xfce4-panel xfce4-power-manager xfce4-pulseaudio-plugin xfce4-screenshooter xfce4-session xfce4-settings xfce4-systemload-plugin xfce4-taskmanager xfce4-terminal xfce4-weather-plugin xfconf xfdesktop"

HELP="Options:
   $0 -b | --build     - Builds and install XFCE4 base and extra apps in a specific order.
   $0 -u | --uninstall - Removes all packages.
"

SECONDS=0

uninstall_packages ()
{
    printf "Removing installed packages.\\n"
    for package in $XFCE $WITH_SLACK
    do
        if is_installed "$package"
        then
            printf "Removing package %s.\\n" "$package"
            /sbin/removepkg "$package" &> /dev/null
        fi
    done
}

get_all_source ()
{
    cd $TMP || exit 1
    for APP in $XFCE
    do
        if [[ ! -d "$APP" ]]
        then
            git clone "${SRC_URL}/${APP}" || exit 1
        else
            cd "$APP" || exit 1
	    printf "Using cloned repo of %s after re-pulling master.\\n" "$APP"
            make clean &> /dev/null
            git checkout master &> /dev/null
            git pull &> /dev/null
            cd ..
        fi
    done
}

init ()
{
    if [[ ! -d "$PKGS" ]]
    then
        mkdir -p "$PKGS"
    fi
    cd "$PKGS" || exit 1
    cd "$TMP" || exit 1
}

is_installed ()
{
    if ls $PACKAGES/"${1}"* &> /dev/null
    then
        return 0
    else
        return 1
    fi
}

fix_perm ()
{
    cd "$1" || exit 1
    find . \
    \( -perm 777 -o -perm 775 -o -perm 711 -o -perm 555 -o -perm 511 \) \
    -exec chmod 755 {} \; -o \
    \( -perm 666 -o -perm 664 -o -perm 600 -o -perm 444 -o -perm 440 -o -perm 400 \) \
    -exec chmod 644 {} \;
}

striper ()
{
    cd "$1" || exit 1
    find . | xargs file | grep "executable" | grep ELF | cut -f 1 -d : | xargs strip --strip-unneeded 2> /dev/null
    find . | xargs file | grep "shared object" | grep ELF | cut -f 1 -d : | xargs strip --strip-unneeded 2> /dev/null
}

mans ()
{
    cd "$1" || exit 1
    if [[ -d usr/man ]]
    then
        cd usr/man || exit
        for manpagedir in $(find . -type d -name "man*")
        do
            cd "$manpagedir" || exit 1
            for eachpage in $( find . -type l -maxdepth 1)
            do
                ln -s "$( readlink "$eachpage" )".gz "$eachpage".gz
                rm "$eachpage"
            done
        gzip -f -9 ./*.?
        done
    fi
}

build_packages ()
{
    cd "$TMP" || exit 1
    printf "Now working on %s.\\n" "$1"
    cd "$1" || exit 1
    fix_perm "$(pwd)"

    make clean

    CFLAGS=$SLKCFLAGS \
        ./autogen.sh \
        --prefix=/usr \
        --libdir=/usr/lib64 \
        --mandir=/usr/man \
        --enable-gtk-doc \
        --docdir=/usr/doc/"$1"-git \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --enable-shared=yes \
        --enable-gtk3 \
        --enable-libnotify \
        --enable-keybinder \
        --enable-pluggable-dialogs \
        --enable-sound-settings \
        --enable-libxklavier \
        --enable-xrandr \
        --enable-xcursor \
        --enable-gio-unix \
        --enable-notifications \
        --enable-thunarx \
        --enable-exif \
        --enable-pcre \
        --enable-dbus \
        --enable-gudev \
        --with-mixer-command=pavucontrol \
        --disable-static \
        --disable-debug \
        --with-vendor-info=Slackware \
        --build=x86_64-slackware-linux || exit 1

    printf "Building %s.\\n" "$1"
    make || exit 1

    PKG="$TMP/package-$1"
    rm -rf "$PKG"
    mkdir -p "$PKG"
    printf "Creating a package for %s.\\n" "$1"
    make install DESTDIR="$PKG" || exit 1

    mkdir -p "$PKG/usr/doc/$1-git" || exit 1
    cp -a \
    AUTHORS BUGS COMPOSITOR COPYING* FAQ HACKING INSTALL NEWS NOTES README* THANKS TODO ChangeLog \
    "$PKG/usr/doc/$1-git" 2> /dev/null

    striper "$PKG"
    mans "$PKG"

    find "$PKG/usr/share/icons" -type f -name "icon-theme.cache" -exec rm -f {} \; 2> /dev/null

    cd "$PKG" || exit 1
    FINAL="$TMP/$1-git-x86_64-1_cmyster.txz"
    /sbin/makepkg -l y -c n "$FINAL" || exit 1

    printf "Installing %s.\\n" "$1"
    /sbin/installpkg "$FINAL" || exit 1
    mv "$FINAL" "$PKGS"

    printf "\n\nDone working on %s.\n\n" "$1"
}


build_all ()
{
    uninstall_packages
    get_all_source

    for component in $XFCE
    do
        build_packages "$component" xfce
    done

    libtool --finish /usr/lib64/ &> /dev/null
    printf "Done.\nIt took %s minutes and %s seconds to build it all.\n" "$(( SECONDS / 60 ))" "$(( SECONDS % 60 ))"
}

case "$1" in
        --build)
	        init
	        build_all
            ;;
        -b)
		    init
		    build_all
            ;;
         --list)
		    init
		    list_installed
            ;;
         -l)
	        init
		    list_installed
            ;;
    --uninstall) uninstall_packages ;;
             -u) uninstall_packages ;;
              *) printf "%s" "$HELP" && exit 0 ;;
esac

