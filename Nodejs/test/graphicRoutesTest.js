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

var routes = require('../lib/GraphicServer/routes/index.js');

// Requirements for mongo connection
var Server = mongo.Server,
Db = mongo.Db,
BSON = mongo.BSONPure;

//app.use(express.bodyParser());

describe('Graphic_server',function(){

	var checkForHexRegExp = new RegExp("^[0-9a-fA-F]{24}$")
    var testDB;
    var configArgs = {};
    configArgs.db_port = "55517";
    configArgs.db_host = "theplant.guru";
    configArgs.db_database = "development";
    configArgs.classifier_host = "146.169.49.11";
    configArgs.classifier_port = "55581";
    configArgs.appServer_port = "55580";

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

	    }

	// Set up the middleware for testing
	app.get('/', routes.index);
	app.post('/upload', routes.upload(testDB,configArgs));
	//app.get('/job/:group_id', routes.getJob(testDB));
	//app.get('/job', routes.getJob(testDB));
	//app.post('/upload_no_db', routes.upload(null,configArgs));
	done();



	});


    });

    after(function(done){

	testDB.close();
	done();
    });

    describe('routes.classify', function(){

		it('should accept an image upload and respond with a new valid objectID', function(done){
			this.timeout(4000);
		    request(app)
			.post('/classify')
			//.field("", null)
			//.field("", null)
			//.field("", null)
			//.field("", null)
			//.field("", null)
			//.field("", null)
			//.field("date", null)
			//.field("latitude", null)
			//.field("longitude", null)
			//.field("group_id", 0)
			//.field("segment", "flower")
			.attach('datafile','./test/fixtures/sample.jpg')
			.expect(200,"File received by graphic")
			.end()
			/*
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
			*/

		});



})