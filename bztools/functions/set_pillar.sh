#!/bin/bash
set_pillar ()
{
    # Define the runtime arguments that are used to determin the pillar.
    case $1 in
        "MetalManagement")
            export NAME="$MEM_NAME"
            export BZ_Q="$MEM_BZ_Q"
            export TO="$MEM_TO"
            export FROM="$MEM_FROM"
            export CARES="$MEM_CARES"
            ;;
        "Management")
            export NAME="$MGT_NAME"
            export BZ_Q="$MGT_BZ_Q"
            export TO="$MGT_TO"
            export FROM="$MGT_FROM"
            export CARES="$MGT_CARES"
            ;;
        "CNF")
            export NAME="$CNF_NAME"
            export BZ_Q="$CNF_BZ_Q"
            export TO="$CNF_TO"
            export FROM="$CNF_FROM"
            export CARES="$CNF_CARES"
            ;;
        "Customer")
            export NAME="$CST_NAME"
            export BZ_Q="$CST_BZ_QO"
            export TO="$CST_TO"
            export FROM="$CST_FROM"
            export CARES="$CST_CARES"
            ;;
        "Blocker")
            export NAME="$BLK_NAME"
            export TO="$BLK_TO"
            export FROM="$BLK_FROM"
            ;;
        *)
            echo -e "$HELP"
            exit 0
            ;;
    esac

    case $2 in
        "-m")
            export TYPE="MISSING"
            ;;
        "-l")
            export TYPE="LIFECYCLE"
            ;;
        "-b")
            export TYPE="BLOCKER"
            ;;
        *)
            echo -e "$HELP"
            exit 0
            ;;
    esac

    export REPORT="${NAME}_report"
    export WORK_DIR="${WORK_DIR}_$NAME"
}
