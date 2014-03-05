/*****************************
* Pre-requisites for testing 
******************************/

// Node Modules
var assert = require('assert');

// Custom Modules
// Paths here are relative to the folder in which this script lies.
var bucketing = require('../lib/utils/bucketing').bucketing;
var aggregation_count = require('../lib/utils/bucketing').initialise_count_agg;

/******************************
* Actual tests
******************************/


describe('Bucketing Algorithm',function(){

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

});





