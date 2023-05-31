#!/bin/bash
cd ~

function mv_rc ()
{
    for rc in $(find  ~/gdrive/rc_files/ -mindepth 1 -maxdepth 1)
    do
        if [ find -maxdepth 1 -name $rc &> /dev/null ]
        then
            rm -rf $rc
        fi
        ln -s $rc
    done
}

function main_dirs ()
{
    for d in Videos Templates Public Pictures Music Documents irclogs scripts bin
    do
        rm -rf $d
        ln -s ~/gdrive/${d}
    done
}

if [ -z $1 ]
then
    echo "
mv_rc - to move rc files from gdrive.
main_dirs - delete regular folders and link from gdrive.
"
else
    $1
fi
