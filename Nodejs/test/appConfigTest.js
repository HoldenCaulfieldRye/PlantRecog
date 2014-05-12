/*****************************
* Pre-requisites for testing 
******************************/

// Node Modules
var assert = require('assert');

// Custom Modules
// Paths here are relative to the folder in which this script lies.
var parseConfig = require('../lib/AppServer/config_parser').parseConfig;

/******************************
* Actual tests
******************************/
describe('Application_server',function(){
	

	describe('.parseConfig',function(){
		// Runs synchronously. 
		it('should pass good config', function(){
			// Path relative to mocha i.e. within the Nodejs folder
			configArgs = parseConfig('../env/graphic_dev_env.conf');
			assert.equal(configArgs.db_database,'development');
			assert.equal(configArgs.db_port,'55517');
			assert.equal(configArgs.db_host,'theplant.guru');
			assert.equal(configArgs.classifier_host,'graphic02.doc.ic.ac.uk');
			assert.equal(configArgs.classifier_port,'55581');
			assert.equal(configArgs.appServer_port,'55580');
		});
	
		it('should fail on no conf file with -1', function(){
			// Path relative to mocha i.e. within the Nodejs folder
			configArgs = parseConfig('');
			assert.equal(configArgs,-1);

		});

		it('should fail on bad parse with -2', function(){
		    // Path relative to mocha i.e. within the Nodejs folder
			configArgs = parseConfig('nothing');
			assert.equal(configArgs,-2);
		})

		it('should fail on bad conf file with -3', function(){
		    // Path relative to mocha i.e. within the Nodejs folder
			configArgs = parseConfig('./test/fixtures/broken-pseudo-dist_dev_env.conf');
			assert.equal(configArgs,-3);
		});
	});

});

