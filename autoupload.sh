#!/bin/bash -x
topdir=$PWD
date=`date +%Y%m%d`

mkdir $date
cd $date

if [ -z $1 ]; then
    echo "need IP addr of board!"
    exit 0
fi

ssh-keygen -f "$HOME/.ssh/known_hosts" -R $1

scp root@$1:~/vied-viedandr-libcamhal/rpm/libcamhal*.rpm .
scp root@$1:~/vied-viedandr-icamerasrc/rpm/icamerasrc*.rpm .
scp root@$1:~/camera2hal-iotg-cam-hal-rpm/rpms/*x86_64.rpm .
if [ $? -ne 0 ]; then
    echo "check your connection with board root@$1 !"
    exit 0
fi

rm *.tar.gz PI_BUILD-*

if [ -d PI_BUILD_libcamhal_Test_Script ]; then
  rm -rf PI_BUILD_libcamhal_Test_Script/test/
else
  mkdir PI_BUILD_libcamhal_Test_Script
fi

if [ -d PI_BUILD_icamerasrc_Test_Script ]; then
  rm -rf PI_BUILD_icamerasrc_Test_Script/test/
else
  mkdir PI_BUILD_icamerasrc_Test_Script
fi

pi=`echo libcamhal*.rpm`
mv libcamhal*.rpm PI_BUILD-$pi

pi=`echo icamerasrc*.rpm`
mv icamerasrc*.rpm PI_BUILD-$pi

scp -r root@$1:~/vied-viedandr-libcamhal/test PI_BUILD_libcamhal_Test_Script
scp -r root@$1:~/vied-viedandr-icamerasrc/test PI_BUILD_icamerasrc_Test_Script

tarpackage=$date-rpm-libcamhal-icamerasrc.tar.gz
tar zcvf $tarpackage *

#send tar packege
mv $tarpackage /home/icg/public_html
mv *.rpm /home/icg/public_html/latest_pi/

cd $topdir
rm -rf $date
