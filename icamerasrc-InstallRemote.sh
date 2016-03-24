#!/bin/bash
rm rpm/*.rpm
make clean
make -j
make rpm
cd rpm
scp *.rpm root@$1:~/
rm icamerasrc*.rpm
ssh root@$1 'rpm -e `rpm -qa | grep icamerasrc` --nodeps'
ssh root@$1 'sudo rpm -ivh --nodeps --noparentdirs --prefix `pkg-config --variable=pluginsdir gstreamer-1.0` icamerasrc*.rpm'
ssh root@$1 'rm icamerasrc*.rpm'
