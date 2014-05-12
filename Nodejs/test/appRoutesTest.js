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
    configArgs.classifier_host = "graphic02.doc.ic.ac.uk";
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
	    	app.get('/job/:group_id', routes.getJob(testDB));
	    	app.get('/job', routes.getJob(testDB));
	    	app.post('/upload', routes.upload(testDB,configArgs));
	    	app.post('/upload_no_db', routes.upload(null,configArgs));
	    	app.put('/completion/:group_id', routes.putComplete(testDB));
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


	it('should error with invalid GroupID', function(done){
	    jobID = '';
	    request(app)
		.get('/job/zzzz')
		.expect(200,'You did not submit a valid GroupID!')
		.end(function(err,res){
		    if(err){
			done(err);
		    }
		    else {
			done();
		    };
		});
	});

	it('should error with no GroupID', function(done){
	    request(app)
		.get('/job')
		.expect(200,'You did not submit a GroupID')
		.end(function(err,res){
		    if(err){
			done(err);
		    }
		    else {
			done();
		    };
		});
	});

	it('should error with no GroupID', function(done){
	    request(app)
		.get('/job/')
		.expect(200,'You did not submit a GroupID')
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
  			"_id": "5329bda4ec1ac97a1820fafd",
  			"classification": "{ \"crucifer\":0.326, \"sweet melon\":0.188, \"magnolia\":0.094, \"summer squash\":0.037, \"citrus\":0.026, }\n",
		    "classified_count": 9,
  			"entire": "/homes/sd3112/GroupProject/group-project-master/Nodejs/lib/GraphicServer/uploads/development/5329bda4ec1ac97a1820fafd/73be1f6bfa9a670b12a72f2e870e9208.jpg",
  			"group_status": "Cancelled",
		    "image_count": 1
	    }

	    request(app)
		.get('/job/5329bda4ec1ac97a1820fafd')
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
		.expect(200, 'There is no document in the collection matching that GroupID!')
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

		it('should accept an image upload and respond with a new valid objectID', function(done){
			this.timeout(4000);
		    request(app)
			.post('/upload')
			.field("date", null)
			.field("latitude", null)
			.field("longitude", null)
			.field("group_id", 0)
			.field("segment", "flower")
			.attach('datafile','./test/fixtures/sample.jpg')
			.expect(200)
			.end(function(err,res){
			    if(err){
				done(err);
			    }
			    else {
			    assert(checkForHexRegExp.test(res.body.id));
			    assert(checkForHexRegExp.test(res.body.group_id));
			    setTimeout(done, 3000);
			    };
			});

		});

		it('should accept an image upload and respond with the same objectID', function(done){
			this.timeout(4000);
			g_id = "531b4461aa4b00752588b5d7";
		    request(app)
			.post('/upload')
			.field("date", null)
			.field("latitude", null)
			.field("longitude", null)
			.field("group_id", g_id)
			.field("segment", "flower")
			.attach('datafile','./test/fixtures/sample.jpg')
			.expect(200)
			.end(function(err,res){
			    if(err){
				done(err);
			    }
			    else {
			    assert(checkForHexRegExp.test(res.body.id));
			    assert(res.body.group_id === g_id );
			    setTimeout(done, 3000);
			    };
			});

		});

		it('should reject a text groupID', function(done){
			//this.timeout(4000);
			g_id = "531b4461aa4b00752588b5d7";
		    request(app)
			.post('/upload')
			.field("date", null)
			.field("latitude", null)
			.field("longitude", null)
			.field("group_id", "notagroupid")
			.field("segment", "flower")
			.attach('datafile','./test/fixtures/sample.jpg')
			.expect(200, 'You did not submit a valid GroupID!')
			.end(function(err,res){
			    if(err){
				done(err);
			    }
			    else {
			    done();
			    };
			});

		});

		it('should reject a numeric but non 24 length HEX groupID', function(done){
			//this.timeout(4000);
			g_id = "531b4461aa4b00752588b5d7";
		    request(app)
			.post('/upload')
			.field("date", null)
			.field("latitude", null)
			.field("longitude", null)
			.field("group_id", 17)
			.field("segment", "flower")
			.attach('datafile','./test/fixtures/sample.jpg')
			.expect(200, 'You did not submit a valid GroupID!')
			.end(function(err,res){
			    if(err){
				done(err);
			    }
			    else {
			    done();
			    };
			});

		});

		it('should reject a numeric string groupID', function(done){
			//this.timeout(4000);
			g_id = "531b4461aa4b00752588b5d7";
		    request(app)
			.post('/upload')
			.field("date", null)
			.field("latitude", null)
			.field("longitude", null)
			.field("group_id", "17")
			.field("segment", "flower")
			.attach('datafile','./test/fixtures/sample.jpg')
			.expect(200, 'You did not submit a valid GroupID!')
			.end(function(err,res){
			    if(err){
				done(err);
			    }
			    else {
			    done();
			    };
			});

		});



		it('should gracefully say no image attached', function(done){

		    request(app)
			.post('/upload')
			.field("date", null)
			.field("latitude", null)
			.field("longitude", null)
			.field("group_id", 0)
			.field("segment", "flower")
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

		it('should gracefully say no segment information', function(done){

		    request(app)
			.post('/upload')
			.field("date", null)
			.field("latitude", null)
			.field("longitude", null)
			.field("group_id", 0)
			.attach('datafile','./test/fixtures/sample.jpg')
			.expect(200, 'You did not supply a segment type, I cannot continue')
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
			.field("group_id", 0)
			.field("segment", "flower")
			.attach('datafile','./test/fixtures/sample.jpg')
			.expect(200, 'Error connecting to the Database collections!')
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

	describe('routes.completion', function(){

		it('should accept a completion request and respond with the same objectID and status', function(done){
			this.timeout(4000);
			g_id = "5329bda4ec1ac97a1820fafd";
		    request(app)
			.put('/completion/' + g_id)
			.field("completion", true)
			.expect(200)
			.end(function(err,res){
			    if(err){
				done(err);
			    }
			    else {
			    assert(checkForHexRegExp.test(res.body.group_id));
			    assert(res.body.group_id === g_id);
			    assert(res.body.completion_status === "true");
			    setTimeout(done, 3000);
			    };
			});

		});

		it('should say record was now updated', function(done){
			this.timeout(4000);
			g_id = "5329bda4ec1ac97a1820fafd";
		    request(app)
			.put('/completion/' + g_id)
			.field("completion", false)
			.expect(200)
			.end(function(err,res){
			    if(err){
				done(err);
			    }
			    else {
			    assert(checkForHexRegExp.test(res.body.group_id));
			    assert(res.body.updated === "true");
			    assert(res.body.completion_status = "false");
			    setTimeout(done, 3000);
			    };
			});

		});


		it('should show record not updated', function(done){
			this.timeout(4000);
			g_id = "5329bda4ec1ac97a1820fafd";
		    request(app)
			.put('/completion/' + g_id)
			.field("completion", false)
			.expect(200)
			.end(function(err,res){
			    if(err){
				done(err);
			    }
			    else {
			    assert(checkForHexRegExp.test(res.body.group_id));
			    assert(res.body.updated === "false");
			    assert(res.body.completion_status = "false");
			    setTimeout(done, 3000);
			    };
			});

		});
	});


})