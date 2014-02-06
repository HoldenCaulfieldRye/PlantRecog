#!/bin/bash
#
#	Script that runs unit tests for each code base
#	Author: ghaughian Feb 2014
#
echo "INFO: RUNNING UNIT TESTS ON BRANCH: dev"

echo "******Unit Testing <node.js> code base*******************"
cd ../Nodejs
mocha -R json > mocha_test_results.json; 
node utils/parse_mocha_test_results.js 


echo "******Unit testing machine learning <python> code base***"
cd ../ML
#add commands to run python unit tests

echo "******Unit testing machine learning <C++> code base******"
#add commands to run C++ unit tests
