#!/bin/bash
#
#	Script that runs unit tests for each code base
#	Author: ghaughian Feb 2014
#
echo "INFO: Running unit tests on branch: 'master' "

echo "......Unit Testing <node.js> code base...(master) "
cd ../Nodejs
mocha -R json > mocha_test_results.json; 
node utils/parse_mocha_test_results.js 


echo "......Unit testing machine learning <python> code base..(master)"
cd ../ML
#add commands to run python unit tests

echo "......Unit testing machine learning <C++> code base..(master)"
#add commands to run C++ unit tests
