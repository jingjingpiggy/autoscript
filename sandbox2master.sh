#/bin/bash

git checkout master
git pull

git checkout sandbox
if [ $? -ne 0 ] ; then
  git checkout -b sandbox remotes/origin/sandbox/yocto_startup_1214
fi

git pull

if [ "$1" = "" -o "$2" = "" ] ; then
  echo "please input param1:libcamhal/icamerasrc  param2:old tag  param3:new tag(can be NULL)"
  exit 0
fi

if [ ! -f .git/hooks/commit-msg ] ; then
  echo "cannot submit patch because no usable commit-msg! run: scp -p -P 29418 <user>@icggerrit.ir.intel.com:hooks/commit-msg .git/hooks/"
  exit 0
fi

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
    ;;
  [Nn])
    echo "It's ok..." ;;
  *)
    echo "wrong answer!" ;;
esac
exit 0
