#!/bin/bash -x
topdir=$PWD
date=`date +%Y%m%d`

sudo mkdir $date
cd $date

if [ -z $1 ]; then
    echo "need IP addr of board as parameter. example: ./autoupload_3.sh 10.xxx.xxx.xxx!"
    exit 0
fi

ssh-keygen -f "$HOME/.ssh/known_hosts" -R $1
if [ $? -ne 0 ]; then
    echo "check your connection with board root@$1 !"
    exit 0
fi

sudo scp root@$1:~/vied-viedandr-libcamhal/rpm/libcamhal*.rpm .
sudo scp root@$1:~/vied-viedandr-icamerasrc/rpm/icamerasrc*.rpm .
sudo scp root@$1:~/camera2hal-iotg-cam-hal-rpm/rpms/*x86_64.rpm .

sudo mkdir PI_BUILD_libcamhal_Test_Script

sudo mkdir PI_BUILD_icamerasrc_Test_Script

sudo scp -r root@$1:~/vied-viedandr-libcamhal/test PI_BUILD_libcamhal_Test_Script
sudo scp -r root@$1:~/vied-viedandr-icamerasrc/test PI_BUILD_icamerasrc_Test_Script

tarpackage=$date-rpm-libcamhal-icamerasrc.tar.gz
tar zcvf $tarpackage *

#send tar packege
sudo scp $tarpackage icg@yocto-build1:~/public_html/
sudo scp *.rpm icg@yocto-build1:~/public_html/latest_pi

cd $topdir
sudo rm -rf $date
