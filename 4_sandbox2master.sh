#/bin/bash

topdir=$PWD
date=`date +%Y%m%d`

sudo mkdir $date
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
  	  PATCH_COMMIT_SET[$commit_index]=$commit_id
  	  commit_index=$(($commit_index-1))
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

function submit_libcamhal_patches() {
  cd vied-viedandr-libcamhal
  submit_patches_from_sandbox_2_master $1 $2 $3
}

function submit_icamerasrc_patches() {
  cd vied-viedandr-icamerasrc
  submit_patches_from_sandbox_2_master $1 $2 $3
}

if [ "$1" = "" ] ; then
  echo "please input param1:libcamhal/icamerasrc  param2:old tag  param3:new tag(can be NULL)"
  exit 0
fi

read -p "please input you gerrit user name:" GERRITNAME

git clone ssh://icggerrit.ir.intel.com:29418/vied-viedandr-libcamhal
git clone ssh://icggerrit.ir.intel.com:29418/vied-viedandr-icamerasrc
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
