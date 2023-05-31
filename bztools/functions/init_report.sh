#!/bin/bash

init_report ()
{
    case $TYPE in
        "MISSING")
            init_report_missing
            ;;
        "LIFECYCLE")
            init_report_lifecycle
            ;;
        "BLOCKER")
            init_report_blocker
            ;;
    esac
}
