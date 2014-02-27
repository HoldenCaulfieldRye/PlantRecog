/******************************
* Pre-requisites for testing 
******************************/

// Node Modules
var assert = require('assert');
var mongo = require('mongodb');
var BSON = mongo.BSONPure;

// Custom Modules
// Paths here are relative to the folder in which this script lies.
var parseConfig = require('../lib/AppServer/config_parser').parseConfig;
var routes = require('../lib/AppServer/routes/index.js')

// Connect to database so that we can test our routes
try{    
	var mongoClient = new mongo.MongoClient(new mongo.Server("plantrecogniser.no-ip.biz", "57027"), {native_parser: true});
	mongoClient.open(function(err, mongoClient){if (err) throw err;});
	testDB = mongoClient.db("development");
}
catch(err){
	console.log('Error connecting to Database: ' + err);
	process.exit(1);
}

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
			assert.equal(configArgs.db_port,'57027');
			assert.equal(configArgs.db_host,'plantrecogniser.no-ip.biz');
			assert.equal(configArgs.classifier_host,'146.169.49.11');
			assert.equal(configArgs.classifier_port,'55581');
			assert.equal(configArgs.appServer_port,'55580');
		})
	
		it('should fail on no conf file with -1', function(){
			// Path relative to mocha i.e. within the Nodejs folder
			configArgs = parseConfig('');
			assert.equal(configArgs,-1);

		})

		it('should fail on bad parse with -2', function(){
		    // Path relative to mocha i.e. within the Nodejs folder
			configArgs = parseConfig('nothing')
			assert.equal(configArgs,-2)
		})

		it('should fail on bad conf file with -3', function(){
		    // Path relative to mocha i.e. within the Nodejs folder
			configArgs = parseConfig('./test/fixtures/broken-pseudo-dist_dev_env.conf')
			assert.equal(configArgs,-3)
		})
	})
})

/*
describe("Here's another test",function(){
	describe("#parseConfig",function(){
		// Runs synchronously. 
		it("connection parameters should be correct", function(){
			configArgs = parseConfig('../../env/graphic_dev_env.conf')
			assert.equal(configArgs.db_database,'development')
		})
	})
})
*/