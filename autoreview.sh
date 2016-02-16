#/bin/bash

function acquire_latest_code_and_review_patch() {
  cd $TOPDIR/$DATE/vied-viedandr-$1
  git checkout -b sandbox remotes/origin/sandbox/yocto_startup_1214

  scp -p -P 29418 $gerritname@icggerrit.ir.intel.com:hooks/commit-msg .git/hooks/

  project="vied-viedandr-$1"
  #change-id array
  change_id_index=0

  #calculate number of patches
  num_of_patch=`git log --no-merges --format="%H" $2..$3 | wc -l`

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
              commit_id=`git log --no-merges --format="%H %ae" $2..$3 | sed -n $i'p' | awk '{print $1}'`
              mail=`git log --no-merges --format="%H %ae" $2..$3 | sed -n $i'p' | awk '{print $2}'`
              commit_msg=`git log --no-merges --format="%s" $2..$3 | sed -n $i'p'`

              #if not the author himself,then he can review,or break
              if [ $useremail != $mail ]; then
                  #get the whole str of change-id of this patch
                  change_id_index=$(($change_id_index+1))
                  change_id=`ssh $gerritname@icggerrit.ir.intel.com -p 29418 gerrit query project:$project status:merged branch:sandbox/yocto_startup_1214 commit:$commit_id | grep "Change-Id"`
                  change_id=`echo $change_id | cut -d ':' -f 2`
                  change_id=`echo ${change_id:1}`

                  #get the whole str of commit-id of this patch on master branch
                  commit_id_master=`ssh $gerritname@icggerrit.ir.intel.com -p 29418 gerrit query --current-patch-set branch:master change:$change_id | grep "revision"`
                  commit_id_master=`echo $commit_id_master | cut -d ':' -f 2`
                  commit_id_master=`echo ${commit_id_master:1}`
                  echo "patch commit message:$commit_msg Change-Id:$change_id commit-id on master branch:$commit_id_master"

                  #start reviewing,Approver+1 review+1
                  ssh $gerritname@icggerrit.ir.intel.com -p 29418 gerrit review $commit_id_master --code-review +1 --approver +1
              fi
          done
          ;;
      [Nn])
          echo "It's ok..." ;;
      *)
          echo "wrong answer!" ;;
  esac

}


if [ "$1" = "" -o "$2" = "" ] ; then
  echo "please input param1:old tag  param2:new tag"
  exit 0
fi

read -p "please input your email address(xx@intel.com):" useremail
read -p "please input your gerrit user name:" gerritname

TOPDIR=$PWD
DATE=`date +%Y%m%d%H`
mkdir $TOPDIR/$DATE
cd $TOPDIR/$DATE
git clone ssh://icggerrit.ir.intel.com:29418/vied-viedandr-libcamhal
git clone ssh://icggerrit.ir.intel.com:29418/vied-viedandr-icamerasrc

acquire_latest_code_and_review_patch libcamhal $1 $2

acquire_latest_code_and_review_patch icamerasrc $1 $2

rm -rf $TOPDIR/$DATE
