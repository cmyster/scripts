#!/bin/bash

tomcat_service="Tomcat6"
pr_service="ProcessRunner"

# net start uses short and long names, best if we grep a part of it
net start | grep -i tomcat
retval=$?
if [ $retval -ne 0 ]
then
    echo "$tomcat_service is already down."
    export EXIT=0
else
    echo "stoping the $tomcat_service service"
    net stop $tomcat_service &> /dev/null
    retval=$?
    if [ $retval -ne 0 ]
    then    
        echo "Please try to stop $tomcat_service manually and try again."
        export EXIT=1
    fi
fi

net start | grep -i $pr_service
retval=$?
if [ $retval -ne 0 ]
then
    echo "$pr_service is already down."
    export EXIT=0
else
    echo "stoping the $pr_service service"
    net stop $pr_service &> /dev/null
    retval=$?
    if [ $retval -ne 0 ]
    then    
        echo "Please try to stop $pr_service manually and try again."
        export EXIT=1
    fi
fi
exit $EXIT

