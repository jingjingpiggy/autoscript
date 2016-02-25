#!/bin/bash
TOPDIR=$PWD
LIBCAMHAL_CODE_DIR=$TOPDIR/vied-viedandr-libcamhal
ICAMERASRC_CODE_DIR=$TOPDIR/vied-viedandr-icamerasrc
DEPENDENCY_RPMS_DIR=$TOPDIR/dependency_rpms
STEP_NUM=1;
DATE=`date +%Y%m%d`
LOGFILE=$TOPDIR/$DATE.log

WORKWEEK=`expr $(date +%W) + 1`
WORKDAY=`echo $(date +%w)`

if [ $WORKWEEK -lt 10 ] ; then
  RELEASE_FILE="ww0$WORKWEEK.$WORKDAY"
else
  RELEASE_FILE="ww$WORKWEEK.$WORKDAY"
fi

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
  if [ -z "$1" ]; then
      echo "If you want to build camhal & camsrc, you must source toolchain, add toolchain url in param 1."
      exit 0
  fi

  dir=$1
  if [ ! -d $dir ]; then
    return 1
  else
    return 0
  fi
}

function get_latest_code() {
  LOGSTEP $FUNCNAME
  if [ -z $1 ] || [ -z $2 ] ; then
      LOGI "you should input both commit id of libcamhal and icamerasrc"
      exit 0
  fi

  LOGI "get latest libcamhal"
  check_directory $LIBCAMHAL_CODE_DIR
  result=$?
  if [ $result -ne 0 ] ; then
    git clone ssh://icggerrit.ir.intel.com:29418/vied-viedandr-libcamhal
    cd $LIBCAMHAL_CODE_DIR
    git checkout -b sandbox remotes/origin/sandbox/yocto_startup_1214
    git pull
    git reset --hard $1
  else
    cd $LIBCAMHAL_CODE_DIR
    git checkout sandbox
    git pull
    git reset --hard $1
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
    git reset --hard $2
  else
    cd $ICAMERASRC_CODE_DIR
    git checkout sandbox
    git pull
    cd $ICAMERASRC_CODE_DIR
    git reset --hard $2
  fi

}

function update_dependency_rpm() {
  LOGSTEP $FUNCNAME
  cd $TOPDIR
  check_directory $DEPENDENCY_RPMS_DIR
  if [ $? -ne 0 ] ; then
    mkdir dependency_rpms
  else
    rm -rf dependency_rpms/*
  fi

  scp icg@yocto-build1:/home/share/iotg_daily_release/$RELEASE_FILE/libcamhal-*.rpm dependency_rpms/
  CHECK_RESULT $? "get libcamhal rpm"
  scp icg@yocto-build1:/home/share/iotg_daily_release/$RELEASE_FILE/icamerasrc-*.rpm dependency_rpms/
  CHECK_RESULT $? "get icamerasrc rpm"
  scp icg@yocto-build1:/home/share/iotg_daily_release/$RELEASE_FILE/aiqb-*.rpm dependency_rpms/
  CHECK_RESULT $? "get aiqb rpm"
  scp icg@yocto-build1:/home/share/iotg_daily_release/$RELEASE_FILE/libiacss-*.rpm dependency_rpms/
  CHECK_RESULT $? "get libiacss rpm"
  scp icg@yocto-build1:/home/share/iotg_daily_release/$RELEASE_FILE/libiaaiq-*.rpm dependency_rpms/
  CHECK_RESULT $? "get libiaaiq rpm"
  cd dependency_rpms
  sudo rpm -e `sudo rpm -qa | grep libiaaiq` --nodeps
  sudo rpm -ivh libiaaiq-*.rpm --nodeps
  sudo rpm -e `sudo rpm -qa | grep aiqb` --nodeps
  sudo rpm -ivh aiqb-*.rpm --nodeps
  sudo rpm -e `sudo rpm -qa | grep libiacss` --nodeps
  sudo rpm -ivh libiacss-*.rpm --nodeps
  cd $TOPDIR
}

function source_toolchain() {
  LOGSTEP $FUNCNAM

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
}

function build_icamerasrc_test() {
  LOGSTEP $FUNCNAME
  cd $ICAMERASRC_CODE_DIR/test
  make clean
  make -j LIBCAMHAL_DIR=$LIBCAMHAL_CODE_DIR
  CHECK_FILE icamsrc_test

  cd $ICAMERASRC_CODE_DIR/test/utils
  make -j LIBCAMHAL_DIR=$LIBCAMHAL_CODE_DIR
  CHECK_FILE gst-tool
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
      ssh root@$1 'rm -rf libcamhal_UT/ icamerasrc_UT/ dependency_rpms/'

      cp -r vied-viedandr-libcamhal/test .
      mv test/ libcamhal_UT/
      scp -r libcamhal_UT/ root@$1:~/
      rm -rf libcamhal_UT
      
      cp -r vied-viedandr-icamerasrc/test .
      mv test/ icamerasrc_UT/
      scp -r icamerasrc_UT/ root@$1:~/
      rm -rf icamerasrc_UT
      
      scp -r dependency_rpms/ root@$1:~/
  fi
}

source_toolchain $1

get_latest_code $2 $3

update_dependency_rpm

build_libcamhal
build_libcamhal_test
build_install_libcamhal_rpm

build_icamerasrc
build_icamerasrc_test
build_icamerasrc_rpm

copy_source_code_and_dependency_rpms_to_board $4
exit 0


TODO
