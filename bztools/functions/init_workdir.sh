#!/bin/bash
init_workdir ()
{
    # Make sure the work directory is there and empty.
    if [ ! -d "$WORK_DIR" ]
    then
        mkdir -p "$WORK_DIR" || exit 1
    fi

    cd "$WORK_DIR" || exit 1
    rm -rf ./*
}
