/*****************************
* Pre-requisites for testing 
******************************/

// Node Modules
var assert = require('assert');
// Custom Modules
// Paths here are relative to the folder in which this script lies.
//Export the confile so we can test the app!
var confFile = '../env/pseudo-dist_dev_env.conf';
exports.conf = confFile;
// Start the app
var myApp = require('../lib/GraphicServer/graphic.js')


/******************************
* Actual tests
******************************/
describe('Graphic_server',function(){
	
	describe('.App',function(){

		//
		// Open DB connection before doing tests.
		before(function(done){
			/* Code to allow connection to mongo, gets new instance of MongoClient */
	      	done();
	    });

	    it('should do sweet fa', function(){
			// Path relative to mocha i.e. within the Nodejs folder

		});
	});

});

