/*****************************
* Pre-requisites for testing 
******************************/

// Node Modules
var assert = require('assert');
var mongo = require('mongodb');
var BSON = mongo.BSONPure;

// Custom Modules
// Paths here are relative to the folder in which this script lies.
//var bucketing = require('../lib/utils/bucketing').bucketing;
//var aggregation_count = require(module, '../lib/utils/node_bucketing');
var aggregation_count = require('../lib/utils/node_bucketing').aggregation_count;
var traverse_update_descendant_count = require('../lib/utils/node_bucketing').traverse_update_descendant_count;
var traverse_update_bucket = require('../lib/utils/node_bucketing').traverse_update_bucket;

// Requirements for mongo connection
var Server = mongo.Server,
Db = mongo.Db,
BSON = mongo.BSONPure;

/******************************
* Actual tests
******************************/

describe('Bucketing Algorithm',function(){
	var db;
	// Open DB connection before doing tests.
	before(function(done){
	    var server = new Server('theplant.guru','55517',{auto_reconnect:true, native_parser: true});
	    db = new Db('development',server, {safe: true});
	    db.open(function(err, testDB) {
	    	if(!err) console.log("Connected to " + 'development' + " database");
	    });
	    done();
	});

	after(function(done){
		db.close();
		done();
	});

	describe('aggregation_count',function(){
		it('should pass with any plant tag and probability', function(){
			assert.equal(aggregation_count(null,    0.0), 1);
			assert.equal(aggregation_count('Leaf',  0.0), 1);
			assert.equal(aggregation_count('Entire',0.0), 1);
			assert.equal(aggregation_count('Branch',0.7), 1);
			assert.equal(aggregation_count('Fruit', 0.7), 1);
			assert.equal(aggregation_count('Stem',  1.0), 1);
			assert.equal(aggregation_count('Flower',0.5), 1);
		});

	});
	
	describe('traverse_update_descendant_count',function(){
		it('should pass with non empty tree path', function(){
			assert.equal(traverse_update_descendant_count(["n11545714","n11545524","n13083586","n00017222"]), 1);
		});
		it('should fail if a path is empty', function(){
			assert.equal(traverse_update_descendant_count([]), -1);
		});
	});
	
	describe('traverse_update_bucket',function(){
		it('should pass with non empty tree path', function(){
			assert.equal(traverse_update_bucket(["n11545714","n11545524","n13083586","n00017222"]), 1);
		});
		it('should fail if a path is empty', function(){
			assert.equal(traverse_update_bucket([]), -1);
		});
	});

});


