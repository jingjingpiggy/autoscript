#!/bin/bash
TOPDIR=$PWD
LIBCAMHAL_CODE_DIR=$TOPDIR/vied-viedandr-libcamhal
ICAMERASRC_CODE_DIR=$TOPDIR/vied-viedandr-icamerasrc
GERRITNAME=
STEP_NUM=1;
DATE=`date +%Y%m%d`
LOGFILE=$TOPDIR/$DATE.log

function LOGSTEP() {
  echo "STEP $STEP_NUM $1" | tee -a $LOGFILE
  STEP_NUM=$(($STEP_NUM+1))
}

function LOGI() {
  echo "$*" | tee -a $LOGFILE
}

function CHECK_RESULT() {
  if [ $1 -eq 0 ]; then
      LOGI $2 "success"
  else
      LOGI $2 "fail"
      exit 0
  fi
}

function CHECK_FILE() {
  if [ -f $1 ]; then
      LOGI "file" $1 "exist"
  else
      LOGI "file" $1 "non-exist"
      exit 0
  fi
}

function check_directory() {
  LOGSTEP $FUNCNAME $1

  dir=$1
  if [ ! -d $dir ]; then
    return 1
  else
    return 0
  fi
}

function get_latest_code() {
  LOGSTEP $FUNCNAME

  LOGI "get latest libcamhal"
  check_directory $LIBCAMHAL_CODE_DIR
  result=$?
  if [ $result -ne 0 ] ; then
    git clone ssh://icggerrit.ir.intel.com:29418/vied-viedandr-libcamhal
    cd $LIBCAMHAL_CODE_DIR
    git checkout -b sandbox remotes/origin/sandbox/yocto_startup_1214
    git pull
  else
    cd $LIBCAMHAL_CODE_DIR
    git checkout sandbox
    git pull
  fi

  cd $TOPDIR

  LOGI "get latest icamerasrc"
  check_directory $ICAMERASRC_CODE_DIR
  result=$?
  if [ $result -ne 0 ] ; then
    git clone ssh://icggerrit.ir.intel.com:29418/vied-viedandr-icamerasrc
    cd $ICAMERASRC_CODE_DIR
    git checkout -b sandbox remotes/origin/sandbox/yocto_startup_1214
    git pull
  else
    cd $ICAMERASRC_CODE_DIR
    git checkout sandbox
    git pull
  fi

}

function update_dependency_rpm() {
  LOGSTEP $FUNCNAME
  cd $TOPDIR
  check_directory camera2hal-iotg-cam-hal-rpm
  result=$?
  if [ $result -ne 0 ]; then
    git clone ssh://$GERRITNAME@git-ger-6.devtools.intel.com:29418/camera2hal-iotg-cam-hal-rpm
    cd camera2hal-iotg-cam-hal-rpm/rpms
  else
    cd camera2hal-iotg-cam-hal-rpm/rpms
    git pull
  fi
  sudo rpm -e libiaaiq-1.0.0-0.x86_64 --nodeps
  sudo rpm -ivh libiaaiq-1.0.0-0.x86_64.rpm --nodeps
  sudo rpm -e aiqb-1.0.0-0.x86_64 --nodeps
  sudo rpm -ivh aiqb-1.0.0-0.x86_64.rpm --nodeps
  sudo rpm -e libiacss-1.0.0-0.x86_64 --nodeps
  sudo rpm -ivh libiacss-1.0.0-0.x86_64.rpm --nodeps
}


function source_toolchain() {
  LOGSTEP $FUNCNAM
  if [ -z "$1" ]; then
    echo "If you want to build camhal & camsrc, you must source toolchain, add toolchain url in param 1."
    exit 0
  fi

  source "$1"
  CHECK_RESULT $? "source toolchain"
}

function build_libcamhal() {
  LOGSTEP $FUNCNAME
  cd $LIBCAMHAL_CODE_DIR
  autoreconf --install
  CHECK_FILE configure
  ./configure
  make clean
  make -j
  CHECK_RESULT $? "build libcamhal"
}

function build_libcamhal_test() {
  LOGSTEP $FUNCNAME
  cd $LIBCAMHAL_CODE_DIR/test
  make clean
  make -j
  CHECK_FILE libcamhal_test
}

function remove_libcamhal_rpm() {
  LOGSTEP $FUNCNAME
  sudo rpm -e `rpm -qa | grep libcamhal` --allmatches --nodeps
}


function build_install_libcamhal_rpm() {
  LOGSTEP $FUNCNAME
  cd $LIBCAMHAL_CODE_DIR
  rm $LIBCAMHAL_CODE_DIR/rpm/libcamhal-*.rpm
  make rpm
  cd $LIBCAMHAL_CODE_DIR/rpm
  CHECK_FILE libcamhal-*.rpm
  sudo rpm -ivh libcamhal-*.rpm --nodeps
}

function build_icamerasrc() {
  LOGSTEP $FUNCNAME
  cd $ICAMERASRC_CODE_DIR
  autoreconf --install
  CHECK_FILE configure
  CPPFLAGS="-I$LIBCAMHAL_CODE_DIR/include/api -I$LIBCAMHAL_CODE_DIR/include/utils" LDFLAGS="-L$LIBCAMHAL_CODE_DIR/.libs" ./configure
  make clean
  make -j
  CHECK_RESULT $? "build icamerasrc"
  cd test/utils
  make -j LIBCAMHAL_DIR=$LIBCAMHAL_CODE_DIR
  CHECK_FILE gst-tool
}

function build_icamerasrc_test() {
  LOGSTEP $FUNCNAME
  cd $ICAMERASRC_CODE_DIR/test
  make clean
  make -j LIBCAMHAL_DIR=$LIBCAMHAL_CODE_DIR
  CHECK_FILE icamsrc_test
}

function remove_icamerasrc_rpm() {
  LOGSTEP $FUNCNAME
  sudo rpm -e `rpm -qa | grep icamerasrc` --nodeps
}

function build_icamerasrc_rpm() {
  LOGSTEP $FUNCNAME
  cd $ICAMERASRC_CODE_DIR
  rm $ICAMERASRC_CODE_DIR/rpm/icamerasrc-*.rpm
  make rpm
  cd $ICAMERASRC_CODE_DIR/rpm
  CHECK_FILE icamerasrc-*.rpm
}

function copy_source_code_and_dependency_rpms_to_board() {

  cd $TOPDIR
  if [ -z $1 ]; then
      echo "If you want to put source code to board, you must add board IP in param 2."
      exit 0
  else
      ssh-keygen -f "$HOME/.ssh/known_hosts" -R $1
      #remove old code and rpms
      ssh root@$1 'rm -rf vied-viedandr-libcamhal/ vied-viedandr-icamerasrc/ camera2hal-iotg-cam-hal-rpm/'
      scp -r vied-viedandr-* root@$1:~/
      scp -r camera2hal-iotg-cam-hal-rpm/ root@$1:~/
  fi
}

read -p "please input you gerrit user name:" GERRITNAME

get_latest_code
remove_libcamhal_rpm
remove_icamerasrc_rpm

update_dependency_rpm

source_toolchain $1

build_libcamhal
build_libcamhal_test
build_install_libcamhal_rpm

build_icamerasrc
build_icamerasrc_test
build_icamerasrc_rpm

copy_source_code_and_dependency_rpms_to_board $2
ssh root@$2 'sh run_camhal_camsrc_UT.sh'
exit 0

TODO

