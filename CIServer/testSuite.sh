#!/bin/bash 
#
#	A script that will clone a git repo, checkout a designated branch and run an appropriate unit test script on that repo/branch 
#
#	author: Gerard Haughian (Jan 2014)
#	args: $1 = git repo url
#	args: $2 = git ref
#

PROJ_NAME=`echo $1 | awk 'BEGIN {FS="/"}{print $2}' | awk 'BEGIN {FS="."}{print $1}'`

VALID_BRANCHES="master qa dev"
BRANCH=`echo $2 | awk 'BEGIN {FS="/"}{print $3}'`
# if $BRANCH does not appear in the list of VALID_BRANCHES then exit
echo $VALID_BRANCHES | grep $BRANCH
if [ 1 -eq $? ]; then 
	echo "$(date) INFO: The previous git push is not to one of the following branches: $VALID_BRANCHES"
	exit 0
fi

EMAIL_ADDR="gerardhaughian@gmail.com"
#EMAIL_ADDR="doc-g1353012-group@imperial.ac.uk"
EMAIL_SUBJ_PREFIX="Test Suite Results - "
EMAIL_SUBJ=${EMAIL_SUBJ_PREFIX}${PROJ_NAME}:${BRANCH}


#step one: if the repo dir already exists remove it, we want to have a fresh clone from gitlab
if [ -d $PROJ_NAME ] ; then
	echo "$(date) WARN: repo:$PROJ_NAME already exists, removing it."
	rm -rf $PROJ_NAME
fi

#step two: clone the repo and checkout appropriate branch
echo "INFO: cloning repo: $1"
GIT_URL=`echo ${1/gitlab.doc.ic.ac.uk/146.169.13.187}`
git clone $GIT_URL
git pull  $GIT_URL $BRANCH

echo "$(date) INFO: checking out branch: $BRANCH"
cd "$PROJ_NAME/CIServer"
git checkout $BRANCH


#step three: run unit tests
TEST_SCRIPT="test_$BRANCH.sh"
echo "$(date) INFO: running test script: $TEST_SCRIPT"
./bin/$TEST_SCRIPT | mail -s "$EMAIL_SUBJ" $EMAIL_ADDR


cd ../../
#step four: clean up file system
if [ -d $PROJ_NAME ] ; then
	echo "$(date) WARN: removing repo:$PROJ_NAME"
	rm -rf $PROJ_NAME
fi
