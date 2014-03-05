/*****************************
 * Pre-requisites for testing 
 ******************************/

// Node Modules
var assert = require('assert');
var request = require('supertest');
var mongo = require('mongodb');
var BSON = mongo.BSONPure;
var express = require('express');
var formidable = require ('formidable');
var util = require ('util');
var app = express();

// Custom Modules
// Paths here are relative to the folder in which this script lies.

var routes = require('../lib/AppServer/routes/index.js');

// Requirements for mongo connection
var Server = mongo.Server,
Db = mongo.Db,
BSON = mongo.BSONPure;

//app.use(express.bodyParser());

describe('Application_server',function(){

	// RegExp to test id returned //
	var checkForHexRegExp = new RegExp("^[0-9a-fA-F]{24}$")
    var testDB;
    var configArgs = {};
    configArgs.db_port = "55517";
    configArgs.db_host = "theplant.guru";
    configArgs.db_database = "development";
    configArgs.classifier_host = "theplant.guru";
    configArgs.classifier_port = "55581";
    configArgs.appServer_port = "55580";

 
    // Open DB connection before doing tests.
    before(function(done){
	/* Code to allow connection to mongo, gets new instance of MongoClient */

	var server = new Server('theplant.guru','55517',{auto_reconnect:true, native_parser: true});
	testDB = new Db('development',server, {safe: true});

	//Actually connect to the database.
	testDB.open(function(err, testDB) {
	    if(!err) {
	    	console.log("Connected to " + 'development' + " database");
	    	testDB.collection('usercollection', {strict:true}, function(err, collection) {
	    	    if (err) {
	    		console.log("The 'usercollection' collection doesn't exist!");
	    		return -1;
	    	    }
	    	});

	    	// Set up the middleware for testing
	    	app.get('/job/:job_id', routes.getJob(testDB));
	    	app.get('/job', routes.getJob(testDB));
	    	app.post('/upload', routes.upload(testDB,configArgs));
	    	app.post('/upload_no_db', routes.upload(null,configArgs));
	    	done();
	    }
	});


    });

    // Close DB connection after completed tests
    after(function(done){

	testDB.close();
	done();
    });


    // Run some tests!
    describe('.routes.getJob', function(){


	it('should error with invalid jobID', function(done){
	    jobID = '';
	    request(app)
		.get('/job/xx')
		.expect(200,'You did not submit a valid JobID!')
		.end(function(err,res){
		    if(err){
			done(err);
		    }
		    else {
			done();
		    };
		});
	});

	it('should error with no jobID', function(done){
	    request(app)
		.get('/job')
		.expect(200,'You did not submit a JobID')
		.end(function(err,res){
		    if(err){
			done(err);
		    }
		    else {
			done();
		    };
		});
	});

	it('should error with no jobID', function(done){
	    request(app)
		.get('/job/')
		.expect(200,'You did not submit a JobID')
		.end(function(err,res){
		    if(err){
			done(err);
		    }
		    else {
			done();
		    };
		});
	});

	it('should return the right BSON', function(done){

	    // Actual document in Database.
	    var returnedObject = {
		"_id": "5308b98ba073dc607f240ac1",
		"classification": "{ \"Lemon tree\":0.217, \"Pine\":0.174, \"Maple\":0.152 }",
		"graphic_filepath": "Nodejs/lib/GraphicServer/uploads/development/12319-twlq79.jpg",
		"image_metadata": {
		    "date": null,
		    "latitude": null,
		    "longitude": null
		},
		"image_segment": "flower",
		"submission_state": "Image classified",
		"submission_time": 1393080715,
		"vm_filepath": "Nodejs/lib/AppServer/uploads/development/641d11ec6af0d44d2009f7baa68a729e.jpg"
	    }

	    request(app)
		.get('/job/5308b98ba073dc607f240ac1')
		.expect(200, returnedObject)
		.end(function(err,res){
		    if(err){
			done(err);
		    }
		    else {
			done();
		    };
		});
	});

	it('should gracefully say no item', function(done){

	    // Correct ObjectID but ID does not exist
	    request(app)
		.get('/job/5308b98ba073dc607f240ac2')
		.expect(200, 'There is no document in the collection matching that JobID!')
		.end(function(err,res){
		    if(err){
			done(err);
		    }
		    else {
			done();
		    };
		});
	});
	

    });

    describe('routes.upload', function(){

		it('should accept an image upload and respond with valid objectID', function(done){
			this.timeout(4000);
		    request(app)
			.post('/upload')
			.field("date", null)
			.field("latitude", null)
			.field("longitude", null)
			.attach('datafile','./test/fixtures/sample.jpg')
			.expect(200)
			.end(function(err,res){
			    if(err){
				done(err);
			    }
			    else {
			    assert(checkForHexRegExp.test(res.body.id));
			    setTimeout(done, 3000);
			    };
			});

		});

		it('should gracefully say no image attached', function(done){

		    request(app)
			.post('/upload')
			.field("date", null)
			.field("latitude", null)
			.field("longitude", null)
			.expect(200, 'Nothing to add to database: there is no Datafile attached!')
			.end(function(err,res){
			    if(err){
				done(err);
			    }
			    else {
				done();
			    };
			});

		});

		it('should gracefully say db err', function(done){

		    request(app)
			.post('/upload_no_db/')
			.field("date", null)
			.field("latitude", null)
			.field("longitude", null)
			.attach('datafile','./test/fixtures/sample.jpg')
			.expect(200, 'Error connecting to Database collection!')
			.end(function(err,res){
			    if(err){
				done(err);
			    }
			    else {
				done();
			    };
			});

		});
    })


})