#!/bin/bash
make clean
make -j
make rpm
cd rpm
scp *.rpm root@$1:~/
rm libcamhal*.rpm
ssh root@$1 'rpm -e `rpm -qa | grep libcamhal` --nodeps'
ssh root@$1 'sudo rpm -ivh libcamhal-*.rpm --nodeps'
ssh root@$1 'rm libcamhal*.rpm'
