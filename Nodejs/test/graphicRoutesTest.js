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
    configArgs.classifier_host = "graphic02.doc.ic.ac.uk";
    configArgs.classifier_port = "55581";
    configArgs.appServer_port = "55580";

    before(function(done){
	/* Code to allow connection to mongo, gets new instance of MongoClient */

	//var server = 'foo';
	//testDB = 'bar';

	var server = new Server('theplant.guru','55517',{auto_reconnect:true, native_parser: true}    );
	testDB = new Db('development',server, {safe: true});
	/*
	//Actually connect to the database.
	testDB.open(function(err, testDB) {
	    if(!err) {
	    	console.log("Connected to " + 'development' + " database");
	    	testDB.collection('segment_images', {strict:true}, function(err, collection) {
	    	    if (err) {
	    		console.log("The 'segment_images' collection doesn't exist!");
	    		return -1;
	    	    }
	    	});

	    }

	});
    */
	// Set up the middleware for testing
	app.post('/classify', routes.classify(testDB,configArgs));
	//app.get('/job/:group_id', routes.getJob(testDB));
	//app.get('/job', routes.getJob(testDB));
	//app.post('/upload_no_db', routes.upload(null,configArgs));
	done();


    });

    after(function(done){

	testDB.close();
	done();
    });

    describe('routes.classify', function(){

    
		it('should fail with Insufficient arguments supplied', function(){

			this.timeout(8000);
		    request(app)
			.post('/classify')
			.field("group_id", 0)			
			.expect(200,"Insufficient arguments supplied")			
			.end(function(err,res){
			    if(err) throw err;
			});
		});
	
		it('should accept an image upload and respond with There was a problem adding the information to the database.', function(){

			this.timeout(8000);
		    request(app)
			.post('/classify')
			.field("group_id", 0)
			.attach('datafile','./test/fixtures/sample.jpg')
			.expect(200,"There was a problem adding the information to the database." )			
			.end(function(err,res){
			    if(err) throw err;
			});
		});

		/*
		it('should fail with Insufficient arguments supplied', function(){

			this.timeout(4000);
		    request(app)
			.post('/classify')
			.expect(200,"Insufficient arguments supplied")			
			.end(function(err,res){
			    if(err) throw err;

			});
		
		});
		*/

	})
})
