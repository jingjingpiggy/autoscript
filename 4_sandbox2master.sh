#/bin/bash

topdir=$PWD
date=`date +%Y%m%d`

mkdir $date
cd $date
GERRITNAME=

function submit_patches_from_sandbox_2_master() {

  git checkout -b sandbox remotes/origin/sandbox/yocto_startup_1214

  scp -p -P 29418 $GERRITNAME@icggerrit.ir.intel.com:hooks/commit-msg .git/hooks/

  project="vied-viedandr-$1"
  #patch array
  PATCH_COMMIT_SET=()

  #calculate number of patches
  num_of_patch=`git log --no-merges --format="%H" $2..$3 | wc -l`
  commit_index=$num_of_patch

  #confirmation of information
  echo "you are working on $project, old tag is $2, new tag is $3"
  echo -e '\n'

  echo "there are $num_of_patch patches will be submitted to master:"
  git log --no-merges --format="%H %Cblue%s %Cgreen%m %Cred%an" $2..$3
  echo -e '\n'

  read -p "are you sure about input parameters?  (y/n):" yn
  case "$yn" in
    [Yy])
      #save commit id into patch array: PATCH_COMMIT_SET
  	for ((i=1;i<=$num_of_patch;i++))
  	do
  	  commit_id=`git log --no-merges --format="%H" $2..$3 | sed -n $i'p'`
      change_id=`ssh $GERRITNAME@icggerrit.ir.intel.com -p 29418 gerrit query project:$project status:merged branch:sandbox/yocto_startup_1214 commit:$commit_id | grep "Change-Id"`
      change_id=`echo $change_id | cut -d ':' -f 2`
      change_id=`echo ${change_id:1}`

      #now we need to make sure this patch hasn't been merged on master branch..if not, we will proceed, otherwise jump through
      check_if_merged=`ssh $GERRITNAME@icggerrit.ir.intel.com -p 29418 gerrit query --current-patch-set branch:master change:$change_id | grep "MERGED"`
      if [ -z $check_if_merged ] ; then
  	    PATCH_COMMIT_SET[$commit_index]=$commit_id
  	    commit_index=$(($commit_index-1))
      else
        echo "this patch already merged on master branch!"
      fi
  	done

      #switch to master branch
  	git checkout master

      #cherry-pick and push patch to master
  	for ((j=1;j<=$num_of_patch;j++))
  	do
  	  git cherry-pick -s -a ${PATCH_COMMIT_SET[$j]}
  	done
  	git push ssh://icggerrit.ir.intel.com:29418/"$project" HEAD:refs/for/master/sandbox2master

        unset PATCH_COMMIT_SET
      ;;
    [Nn])
      echo "It's ok..." ;;
    *)
      echo "wrong answer!" ;;
  esac
}

function acquire_latest_code_and_review_patch() {
  cd $topdir/$date/vied-viedandr-$1
  git checkout sandbox
  project="vied-viedandr-$1"
  #change-id array
  change_id_index=0

  #calculate number of patches
  num_of_patch=`git log --no-merges --format="%H" $2..$3 | wc -l`
  #confirmation of information
  echo "reviewing $project's patches on master branch"
  echo -e '\n'

  read -p "start now?  (y/n):" yn
  case "$yn" in
      [Yy])
          #save commit id into patch array: PATCH_COMMIT_SET
          for ((i=1;i<=$num_of_patch;i++))
          do
              commit_id=`git log --no-merges --format="%H %ae" $2..$3 | sed -n $i'p' | awk '{print $1}'`
              mail=`git log --no-merges --format="%H %ae" $2..$3 | sed -n $i'p' | awk '{print $2}'`
              commit_msg=`git log --no-merges --format="%s" $2..$3 | sed -n $i'p'`
              #if not the author himself,then he can review,or break

              #get the whole str of change-id of this patch
              change_id_index=$(($change_id_index+1))
              change_id=`ssh $GERRITNAME@icggerrit.ir.intel.com -p 29418 gerrit query project:$project status:merged branch:sandbox/yocto_startup_1214 commit:$commit_id | grep "Change-Id"`
              change_id=`echo $change_id | cut -d ':' -f 2`
              change_id=`echo ${change_id:1}`
              #get the whole str of commit-id of this patch on master branch
              commit_id_master=`ssh $GERRITNAME@icggerrit.ir.intel.com -p 29418 gerrit query --current-patch-set branch:master change:$change_id | grep "revision"`
              commit_id_master=`echo $commit_id_master | cut -d ':' -f 2`
              commit_id_master=`echo ${commit_id_master:1}`
              echo "patch commit message:$commit_msg Change-Id:$change_id commit-id on master branch:$commit_id_master"

              #start reviewing,review+1
              ssh $GERRITNAME@icggerrit.ir.intel.com -p 29418 gerrit review $commit_id_master --code-review +1
          done
          ;;
      [Nn])
          echo "It's ok..." ;;
      *)
          echo "wrong answer!" ;;
  esac

}

function submit_libcamhal_patches() {
  cd vied-viedandr-libcamhal
  submit_patches_from_sandbox_2_master $1 $2 $3
  acquire_latest_code_and_review_patch $1 $2 $3
}

function submit_icamerasrc_patches() {
  cd vied-viedandr-icamerasrc
  #submit_patches_from_sandbox_2_master $1 $2 $3
  acquire_latest_code_and_review_patch $1 $2 $3
}

############
# MAIN
############

if [ -z $1 ] ; then
  echo "please input param1:libcamhal/icamerasrc  param2:old tag  param3:new tag(can be NULL)"
  exit 0
fi

read -p "please input you gerrit user name:" GERRITNAME

git clone ssh://icggerrit.ir.intel.com:29418/vied-viedandr-libcamhal
git clone ssh://icggerrit.ir.intel.com:29418/vied-viedandr-icamerasrc
if [ $? -ne 0 ] ; then
    echo "program exit"
    exit 0
fi
submit_libcamhal_patches libcamhal $1 $2
cd $topdir/$date
submit_icamerasrc_patches icamerasrc $1 $2

cd $topdir
read -p "do you want to delete source code? (y/n):" yn
case "$yn" in
    [Yy])
      rm -rf $date
      echo "code deleted."
      ;;
    [Nn])
      echo "restore code."
      ;;
    *)
      ;;
esac

exit 0
