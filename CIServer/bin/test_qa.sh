#!/bin/bash
#
#	Script that runs unit tests for each code base
#	Author: ghaughian Feb 2014
#
echo "///////// INFO: RUNNING SYSTEM TESTS ON BRANCH: qa /////////"
#run system_startup.sh script to set up a complete environemnt
eval `../bin/system_startup.sh -a start -e qa -q`

echo ""
echo "**************Unit Testing <node.js> Code Base**************"
echo ""
cd ../Nodejs
#mocha -R json-cov > mocha_test_results.json; 
make test-cov
node lib/utils/parse_mocha_test_results.js 
echo ""
echo "***********Integration Testing <node.js> Code Base**********"
echo ""
#run integration script

echo ""
echo "******Unit Testing Machine Learning <python> Code Base******"
echo ""
cd ../ML
#add commands to run python unit tests

echo ""
echo "***Integration Testing Machine Learning <python> Code Base**"
echo ""
#run integration script

echo ""
echo "*******Unit Testing Machine Learning <C++> Code Base********"
echo ""
#add commands to run C++ unit tests

echo ""
echo "****Integration Testing Machine Learning <C++> Code Base****"
echo ""
#run integration script
