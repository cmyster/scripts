#!/bin/bash
# This scripts runs when we log in and prompts for kerberos credentials.
# It is expecting a simple one pc/user authentication
# It has a security hole in the form of free text password as CLI command.
# TODO: maybe move to a password_file when I figure out how to use one.

# set -x

# using absolute paths to bypass nasty aliases

KI=$(which kinit)
KL=$(which klist)
KD=$(which kdestroy)

CRED_FILE=$HOME/tmp-creds
STAT_FILE=$HOME/krb-stat

rm -rf $CRED_FILE
rm -rf $STAT_FILE

$KL -s
if [ $? -eq 0 ]
then
    rm -rf $CRED_FILE
    rm -rf $STAT_FILE
    ALREADY="Authentication seems to be in place. If not, kdestroy and rerun."
    echo $ALREADY
    zenity --info --title="Kerberos Credentials" --text="$ALREADY" &
    exit 0
else
    echo "Please enter your credentials"
    zenity --forms --title="Kerberos Credentials" \
    --add-entry="Username" \
    --add-entry="DOMAIN" \
    --add-password="Password" > $CRED_FILE

    case $? in
    0)
        USER=$(cut -d "|" -f 1 $CRED_FILE)
        DOMAIN=$(cut -d "|" -f 2 $CRED_FILE)
        PASS=$(cut -d "|" -f 3 $CRED_FILE)

        echo $PASS | $KI $USER@$DOMAIN

        $KL -s
        if [ $? -eq 0 ]
        then
            $KL &> $STAT_FILE
            FILE=$(grep FILE $STAT_FILE | cut -d ":" -f 3)
            PRINCIPAL=$(grep "Default principal" $STAT_FILE | cut -d " " -f 3)
            EXPIRES=$(grep "krbtgt" $STAT_FILE | cut -d " " -f 4-5)

            zenity \
                --list \
                --title="Kerberos" \
                --text "Current status" \
                --column="Field" \
                --column="Value" \
                "File" "$FILE" \
                "Principal" "$PRINCIPAL" \
                "Expires" "$EXPIRES"

        else
            zenity --warning --text "Authentication failed"
        fi
        ;;

    *)
        zenity --warning --text "No Kerberos authentication"
        ;;
esac

fi

rm -rf $CRED_FILE
rm -rf $STAT_FILE
