#!/bin/bash

cd /cygdrive/c/Apache/Tomcat
rm -rf work/*
rm -rf temp/*
rm -rf logs/*
cd webapps
ls -1 | grep -v "\.war\|openejb\|ROOT\|images\|BellManagement\|csr\|DeviceConfiguration" | xargs rm -rf
