#!/bin/bash

# this script will take take recipient and message body as input,
# and uses sendmail to send it.
# there are 3 regionns to this script:
#    SETTINGS - making sure we know all the properties.
#    SANITY   - making sure the proparties won't fail mutt later.
#    WORK     - where the actual work is done.

###################
# REGION SETTINGS #
###################

# where to keep sent mail items
SENT_DIR=~/mail/sent

# path to pine
SENDMAIL=$(which sendmail)

# get the subject
SUBJECT=$1

# get the address
ADDRESS=$2

# get the attachment(s) path
ATTCH_PATH="\"$3"\"

# which editor is being used
EDITOR=$(which vim)

# signature file to use. please use full path here
SIG=~/.signature

# usage error:
USAGE="usage : $0 \"[subject]\" [recipient] [optional: attachment]"

# setting a unique-ish name for the message body
ATM=$(date +%s)

# date header
DATE=$(date +%x)

# expecting a subject a recipient and an optional attachment
ARGS=("$@")

######################
# ENDREGION SETTINGS #
######################

#################
# REGION SANITY #
#################

# sent directory should be valid
if [ ! -d $SENT_DIR ]
then
    echo "sent folder is missing."
    exit 1
fi

# number of arguments should only be 2 or 3
if [ ${#ARGS[@]} -lt 2 ] || [ ${#ARGS[@]} -gt 3 ]
then
    echo $USAGE
    exit 1
fi

# expecting recipient is a valid-ish mail address
if [[ "$2" != ?*@?*.?* ]]
then
    echo "please provide a valid mail address."
    echo $USAGE
    exit 1
fi

# only if there are 3 arguments AND the 3rd is not empty, we can test for it
#if [ ${#ARGS[@]} -eq 3 ] && [[ "$ATTCH_PATH" != "" ]]
#then
#    # path must be valid. this test needs the original form
#    if [ ! -f $3 ]
#    then
#        echo "$ATTCH_PATH not found."
#        echo $USAGE
#        exit 1
#    else
#        export PARAM=-attachlist
#    fi
#fi

####################
# ENDREGION SANITY #
####################

###############
# REGION WORK #
###############

# creating the message body, the editor needs to save to the same file name.
TMP_BODY=/tmp/message-$ATM.txt
echo "date: $DATE" > $TMP_BODY
echo "to: $ADDRESS" >> $TMP_BODY
echo "subject: $SUBJECT" >> $TMP_BODY
echo -e "\n\n--" >> $TMP_BODY
cat $SIG >> $TMP_BODY


# editing the body
$EDITOR $TMP_BODY

# sending
$SENDMAIL -t < $TMP_BODY

# saving the message and clearing the temp
mv $TMP_BODY $SENT_DIR
rm -rf $TMP_BODY

##################
# ENDREGION WORK #
##################

