#!/bin/bash

TOM_HOM=/cygdrive/c/Apache/Tomcat
LOG_HOM=/cygdrive/c/CommuniTake/logs
CUR_HOM=/cygdrive/c/CommuniTake/CurrentVersion
TIME=$(date +%d%m%a-%H%m)

reDir()
{
    echo clearing $1
    rm -rf $1
    mkdir $1
}

createDir()
{
    if [ ! -d $1 ]
    then
        echo creating $1
        mkdir $1
    fi  
}

zDir()
{
    echo compressing $1
    7z a old-logs/$1-$TIME.7z $1 &> /dev/null 
    rm -rf $1*
}

cd $TOM_HOM

for FOLDER in communitake work temp logs
do
    reDir $FOLDER
done

cd webapps

echo cleaning webapps folder

ls -1 | grep -v openejb | sed 's/*//g' | xargs rm -rf

cd $LOG_HOM

for DIR in old-logs csr sdr
do
    createDir $DIR
done

for DIRTOZIP in sdr csr
do
    zDir $DIRTOZIP
done

echo "compressing current logs"
7z a old-logs/logs-$TIME.7z com.communitake* &> /dev/null
rm -rf com.communitake* 

cd $CUR_HOM
ls -1 | grep -v Config | sed 's/*//g' | xargs rm -rf

cd Config
ls -1 | grep -v Clients | sed 's/*//g' | xargs rm -rf

