tomcat_service="Tomcat6"
pr_service="ProcessRunner"

net start | grep -i tomcat
retval=$?
if [ $retval == 0 ]
then
        echo "$tomcat_service is already up. Exiting."
        exit 1
fi

net start | grep $pr_service
retval=$?
if [ $retval == 0 ]
then
        echo "$pr_service is already up. Exiting."
        exit 1
fi

echo "starting services"

net start $tomcat_service
retval=$?
if [ $retval -ne 0 ]
then
        echo "$tomcat_service did not start. Exiting."
        exit 1
fi

net start $pr_service
retval=$?
if [ $retval -ne 0 ]
then
        echo "$pr_service did not start. Exiting."
        exit 1
fi
exit 0
