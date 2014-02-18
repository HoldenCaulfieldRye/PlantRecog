#!/bin/bash
#
#	Script that runs unit tests for each code base
#	Author: ghaughian Feb 2014
#
echo "////////// INFO: RUNNING UNIT TESTS ON BRANCH: dev /////////"
echo ""
echo "**************Unit Testing <node.js> Code Base**************"
echo ""

cd ../Nodejs
#mocha -R json-cov > mocha_test_results.json; 
rm -r lib-cov
make test-cov
node utils/parse_mocha_test_results.js 

echo ""
echo "******Unit Testing Machine Learning <python> Code Base******"
echo ""

cd ../ML
#add commands to run python unit tests

echo ""
echo "*******Unit Testing Machine Learning <C++> Code Base********"
echo ""
#add commands to run C++ unit tests
