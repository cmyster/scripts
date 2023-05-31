#!/bin/bash

# This function will check if we can login to bugzilla by using
# --ensure-logged-in. If we're not logged in, call an expect script to login.

check_login()
{
    if ! bugzilla --ensure-logged-in query --from-url "$TEST_Q" &> /dev/null
    then
        return 1
    fi
}

