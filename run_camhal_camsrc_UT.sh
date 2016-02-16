#!/bin/bash
TOPDIR=$PWD
SOURCE_CODE_DIR=$TOPDIR
LIBCAMHAL_CODE_DIR=$SOURCE_CODE_DIR/vied-viedandr-libcamhal
ICAMERASRC_CODE_DIR=$SOURCE_CODE_DIR/vied-viedandr-icamerasrc
DEPENDENCY_RPMS_DIR=$SOURCE_CODE_DIR/camera2hal-iotg-cam-hal-rpm


GIT_USER=
STEP_NUM=1;
DATE=`date +%Y%m%d%H%M`
LOGFILE=$SOURCE_CODE_DIR/$DATE.log

function DO_EXECUTE() {
   echo $* | tee -a $LOGFILE
   $* | tee -a $LOGFILE
}

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

function mkdir_directory() {
  LOGSTEP $FUNCNAME $1

  dir=$1
  mkdir -p $dir
}

function get_latest_code() {
  LOGSTEP $FUNCNAME

  cd $SOURCE_CODE_DIR
  LOGI "get latest libcamhal"
  check_directory $LIBCAMHAL_CODE_DIR
  result=$?
  if [ $result -ne 0 ] ; then
    DO_EXECUTE git clone ssh://$GIT_USER@icggerrit.ir.intel.com:29418/vied-viedandr-libcamhal
  else
    cd $LIBCAMHAL_CODE_DIR
    git checkout -b sandbox remotes/origin/sandbox/yocto_startup_1214
    git pull
  fi

  cd $SOURCE_CODE_DIR

  LOGI "get latest icamerasrc"
  check_directory $ICAMERASRC_CODE_DIR
  result=$?
  if [ $result -ne 0 ] ; then
    DO_EXECUTE git clone ssh://$GIT_USER@icggerrit.ir.intel.com:29418/vied-viedandr-icamerasrc
  else
    cd $ICAMERASRC_CODE_DIR
    git checkout -b sandbox remotes/origin/sandbox/yocto_startup_1214
    git pull
  fi

}

function compile_libcamhal_test() {
  LOGSTEP $FUNCNAME
  cd $LIBCAMHAL_CODE_DIR
  autoreconf --install
  make clean
  ./configure
  make -j
  cd $LIBCAMHAL_CODE_DIR/test
  make clean
  dynamic_link=true make -j
  CHECK_FILE libcamhal_test
  cd $LIBCAMHAL_CODE_DIR
}

function compile_icamerasrc_test() {
  LOGSTEP $FUNCNAME
  cd $ICAMERASRC_CODE_DIR
  autoreconf --install
  make clean
  ./configure
  make -j
  cd $ICAMERASRC_CODE_DIR/test
  make clean
  make -j LIBCAMHAL_DIR=$LIBCAMHAL_CODE_DIR
  CHECK_FILE icamsrc_test
}

function build_libcamhal_rpm() {
  LOGSTEP $FUNCNAME
  cd $LIBCAMHAL_CODE_DIR
  make rpm
  CHECK_FILE $LIBCAMHAL_CODE_DIR/rpm/libcamhal-*.rpm
  CHECK_RESULT $? "generate libcamhal rpm"
}

function remove_libcamhal_rpm() {
  LOGSTEP $FUNCNAME
  rpm -e `rpm -qa | grep libcamhal` --allmatches --nodeps
}

function install_libcamhal_rpm() {
  LOGSTEP $FUNCNAME
  cd $LIBCAMHAL_CODE_DIR/rpm
  rpm -ivh --nodeps libcamhal-*.rpm --nodeps
}

function build_icamerasrc_rpm() {
  LOGSTEP $FUNCNAME
  cd $ICAMERASRC_CODE_DIR/rpm
  make rpm
  CHECK_FILE $ICAMERASRC_CODE_DIR/rpm/icamerasrc-*.rpm
  CHECK_RESULT $? "generate icamerasrc rpm"
}

function remove_icamerasrc_rpm() {
  LOGSTEP $FUNCNAME
  rpm -e `rpm -qa | grep icamerasrc` --allmatches --nodeps
}

function install_icamerasrc_rpm() {
  LOGSTEP $FUNCNAME
  cd $ICAMERASRC_CODE_DIR/rpm
  rpm -ivh --nodeps --noparentdirs --prefix `pkg-config --variable=pluginsdir gstreamer-1.0` icamerasrc-*.rpm
}


function run_libcamhal_all_UT_on_B0_tpg() {
  LOGSTEP $FUNCNAME
  cd $LIBCAMHAL_CODE_DIR/test
  DO_EXECUTE ./test-all.py 0
}

function run_libcamhal_all_UT_on_B0_ov13860() {
  LOGSTEP $FUNCNAME
  cd $LIBCAMHAL_CODE_DIR/test
  DO_EXECUTE ./test-all.py 3
}

function run_libcamhal_all_UT_on_imx_185() {
  LOGSTEP $FUNCNAME
  cd $LIBCAMHAL_CODE_DIR/test
  DO_EXECUTE ./test-all.py 8
  DO_EXECUTE ./test-all.py 9
}

function run_icamerasrc_all_UT_on_B0_tpg() {
  LOGSTEP $FUNCNAME
  unset cameraMipiCapture
  export cameraInput=tpg
  cd $ICAMERASRC_CODE_DIR/test
  DO_EXECUTE ./camerasrc_test.sh -p except BGRx RGBx dma UYVY interlace
  mkdir file_for_tpg
  mv *.yuv *.nv12 *.log file_for_tpg/
  mv file_for_tpg/ $SOURCE_CODE_DIR/$DATE
}

function run_icamerasrc_all_UT_on_B0_ov13860() {
  LOGSTEP $FUNCNAME

  unset camieraMipiCapture
  export cameraInput=ov13860
  cd $ICAMERASRC_CODE_DIR/test
  DO_EXECUTE ./camerasrc_test.sh -f Script.gst_launch_icamerasrc_filesink_YUY2_1920_1080
  DO_EXECUTE ./camerasrc_test.sh -f Script.gst_launch_icamerasrc_filesink_NV12_1920_1080
  DO_EXECUTE ./camerasrc_test.sh -f Script.gst_launch_preview_icamerasrc_fakesink_1920_1080_fps

  mkdir file_for_ov13860
  mv *.yuv *.nv12 file_for_ov13860/
  mv file_for_ov13860/ $SOURCE_CODE_DIR/$DATE
}

function update_dependency_rpms() {
  cd $DEPENDENCY_RPMS_DIR/rpms

  sudo rpm -e libiaaiq-1.0.0-0.x86_64 --nodeps
  sudo rpm -ivh libiaaiq-1.0.0-0.x86_64.rpm --nodeps
  sudo rpm -e aiqb-1.0.0-0.x86_64 --nodeps
  sudo rpm -ivh aiqb-1.0.0-0.x86_64.rpm --nodeps
  sudo rpm -e libiacss-1.0.0-0.x86_64 --nodeps
  sudo rpm -ivh libiacss-1.0.0-0.x86_64.rpm --nodeps

}


#############################################################################
# Execute func
#############################################################################

mkdir_directory $SOURCE_CODE_DIR/$DATE

remove_libcamhal_rpm
install_libcamhal_rpm

remove_icamerasrc_rpm
install_icamerasrc_rpm

update_dependency_rpms

#RUN LIBCAMHAL UT
run_libcamhal_all_UT_on_B0_tpg
run_libcamhal_all_UT_on_B0_ov13860
run_libcamhal_all_UT_on_imx_185

#RUN ICAMERASRC UT
run_icamerasrc_all_UT_on_B0_tpg
run_icamerasrc_all_UT_on_B0_ov13860

exit 0

TODO

