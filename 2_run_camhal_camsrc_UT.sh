#!/bin/bash
TOPDIR=$PWD
SOURCE_CODE_DIR=$TOPDIR
LIBCAMHAL_CODE_DIR=$SOURCE_CODE_DIR/libcamhal_UT
ICAMERASRC_CODE_DIR=$SOURCE_CODE_DIR/icamerasrc_UT
DEPENDENCY_RPMS_DIR=$SOURCE_CODE_DIR/dependency_rpms


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

function run_libcamhal_all_UT_on_B0_tpg() {
  LOGSTEP $FUNCNAME
  cd $LIBCAMHAL_CODE_DIR
  DO_EXECUTE ./test-all.py 0
}

function run_libcamhal_all_UT_on_B0_ov13860() {
  LOGSTEP $FUNCNAME
  cd $LIBCAMHAL_CODE_DIR
  DO_EXECUTE ./test-all.py 3
}

function run_libcamhal_all_UT_on_imx_185() {
  LOGSTEP $FUNCNAME
  cd $LIBCAMHAL_CODE_DIR
  DO_EXECUTE ./test-all.py 8
  DO_EXECUTE ./test-all.py 9
}

function run_icamerasrc_all_UT_on_B0_tpg() {
  LOGSTEP $FUNCNAME
  unset cameraMipiCapture
  export cameraInput=tpg
  cd $ICAMERASRC_CODE_DIR
  DO_EXECUTE ./camerasrc_test.sh -p except BGRx RGBx dma UYVY interlace 720_480 720_576 kpi 3A
  mkdir file_for_tpg
  mv *.yuv *.nv12 *.log file_for_tpg/
  mv file_for_tpg/ $SOURCE_CODE_DIR/$DATE
}

function run_icamerasrc_all_UT_on_B0_ov13860() {
  LOGSTEP $FUNCNAME

  unset camieraMipiCapture
  export cameraInput=ov13860
  cd $ICAMERASRC_CODE_DIR
  DO_EXECUTE ./camerasrc_test.sh -f Script.gst_launch_icamerasrc_filesink_YUY2_1920_1080
  DO_EXECUTE ./camerasrc_test.sh -f Script.gst_launch_icamerasrc_filesink_NV12_1920_1080
  DO_EXECUTE ./camerasrc_test.sh -f Script.gst_launch_preview_icamerasrc_fakesink_1920_1080_fps

  mkdir file_for_ov13860
  mv *.yuv *.nv12 file_for_ov13860/
  mv file_for_ov13860/ $SOURCE_CODE_DIR/$DATE
}

function update_dependency_rpms() {
  check_directory $DEPENDENCY_RPMS_DIR
  cd $DEPENDENCY_RPMS_DIR

  rpm -e `rpm -qa | grep libcamhal` --nodeps
  rpm -ivh libcamhal-*.rpm --nodeps
  rpm -e `rpm -qa | grep icamerasrc` --nodeps
  rpm -ivh --nodeps --noparentdirs --prefix `pkg-config --variable=pluginsdir gstreamer-1.0` icamerasrc-*.rpm
  rpm -e `rpm -qa | grep libiaaiq` --nodeps
  rpm -ivh libiaaiq-*.rpm --nodeps
  rpm -e `rpm -qa | grep aiqb` --nodeps
  rpm -ivh aiqb-*.rpm --nodeps
  rpm -e `rpm -qa | grep libiacss` --nodeps
  rpm -ivh libiacss-*.rpm --nodeps
}


#############################################################################
# Execute func
#############################################################################

mkdir_directory $SOURCE_CODE_DIR/$DATE

update_dependency_rpms

#RUN LIBCAMHAL UT
run_libcamhal_all_UT_on_B0_tpg
#run_libcamhal_all_UT_on_B0_ov13860
#run_libcamhal_all_UT_on_imx_185

#RUN ICAMERASRC UT
run_icamerasrc_all_UT_on_B0_tpg
#run_icamerasrc_all_UT_on_B0_ov13860

exit 0

TODO

