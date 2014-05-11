var mongo = require('mongodb');
var BSON = mongo.BSONPure;
var exec = require('child_process').exec;
var async = require('async');
var Q = require('q');

var db_host = process.argv[2];
var db_port = process.argv[3];
var db_database = process.argv[4];

connectToMongo()
	.then(function(db){
		getNetImages(db)
			.then(function(){
		 		cosole.log("got here");
		 	});
	});


function connectToMongo(){
	var deferred = Q.defer();
  	mongoClient = new mongo.MongoClient(new mongo.Server(db_host, db_port), {native_parser: true});
  	mongoClient.open(function(err, mongoClient){
		db = mongoClient.db(db_database);
		deferred.resolve(db);
		return deferred.promise;
	});
})

function getNewImages(db) {
	var deferred = Q.defer();
	db.collection('segment_images').find({"submission_state" : "File received by graphic", "image_segment": components[i]})
								   .sort({"submission_time": -1}).limit(128)
								   .toArray(function(err,docs){
								   		var date = new Date();
										console.log(date);
                      					console.log("Return #" + docs.length + " documents.")
                      					deferred.resolve(docs);
                      					return deferred.promise;
     								});
});