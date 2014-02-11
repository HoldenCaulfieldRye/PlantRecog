#!/bin/bash
#
#	Script that runs unit tests for each code base
#	Author: ghaughian Feb 2014
#
echo "INFO: Running integration tests on branch: 'qa'"

#run system_startup.sh script to set up a complete environemnt
#../bin/system_startup.sh start qa

echo "......Unit Testing <node.js> code base...(qa)"
cd ../Nodejs
mocha -R json-cov > mocha_test_results.json; 
node utils/parse_mocha_test_results.js 

echo "......Integration Testing <node.js> code base...(qa)"


echo "......Unit testing machine learning <python> code base..(qa)"
cd ../ML
#add commands to run python unit tests

echo "......Integration testing machine learning <python> code base..(qa)"


echo "......Unit testing machine learning <C++> code base..(qa)"
#add commands to run C++ unit tests

echo "......Integration testing machine learning <C++> code base..(qa)"
