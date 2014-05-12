var mongo = require('mongodb');
var BSON = mongo.BSONPure;
var exec = require('child_process').exec;
var async = require('async');
var Q = require('q');

var db_host = process.argv[2];
var db_port = process.argv[3];
var db_database = process.argv[4];

console.log("db_host: " + db_host + ", db_port: " + db_port + ", db_database: " + db_database);

connectToMongo(db_host,db_port,db_database, function(db){     // returns the database connection

                /* Query for new images every 2 seconds*/
	        setInterval(function(){
		
		    return getNewImages(db)     // returns all the relevant image documents
			.then(function(docs,err){
			    if(err){console.log("error: " + err)};
			    //if(docs.length != 0) {
				return runClient(docs) // also returns the image documents
 				    .then(function(docs){
					console.log(docs)
					//return updateClassifiedCount(db,docs) // also returns the image documents
					//   .then(function(docs){
					//	return checkGroupCompletion(db,docs);
					
					//    });
				    })
			            

				    .fail(function(err){
				    // runclient.py failed
					console.log("runclient.py failed. Retrying runClient()");
					return runClient(docs) // also returns the image documents
 					    .then(function(docs){
						console.log(docs)
						//return updateClassifiedCount(db,docs) // also returns the image documents
						//   .then(function(docs){
						//	return checkGroupCompletion(db,docs);
						
						//    });
					    })
					    .fail(function(err){
						console.log("runclient.py has failed twice - append dummy data")
						return onError(db,results)
					    })
				    });
			    //}  // end of docs.length != 0 test
	
			});

		}, 2000) // end of setInterval()
	});


/******************** function definitions *************************/

	
function connectToMongo(host,port,database,callback){
        console.log("0) Running connectToMongo()");
  	mongoClient = new mongo.MongoClient(new mongo.Server(host, port), {native_parser: true});
  	mongoClient.open(function(err, mongoClient){
		db = mongoClient.db(database);
		callback(db);
	});
};

function getNewImages(db) {
	var deferred = Q.defer();
        console.log("1) Running getNewImages() ");
	db.collection('segment_images').find({"submission_state" : "File received by graphic"})
				       .sort({"submission_time": -1})
	                               .limit(128)
				       .toArray(function(err,docs){
					   var date = new Date();
					   console.log(date);
                      			   console.log("Return #" + docs.length + " documents.")
                      			   if(err){
					       deferred.reject(new Error(err))}
					   else{
				               deferred.resolve(docs);
					   }
					});
       return deferred.promise;

};

function runClient(results){
    var deferred = Q.defer();
    console.log("2) Running runClient()");
    var count = 0;
    var str = "";
    while(count < results.length){
	str += str + " " + results[count].graphic_filepath;
	count++;
    }
    
    if(count >= results.length){
//	exec('python ./ML/runclient.py entire' + str, function(error,stdout,sterror){
	exec('python ./ML/runclient.py entire ./sample.jpg', function(error,stdout, sterror){ // for testing
	    if(error){
		console.log("Error running runclient.py");
		deferred.reject(new Error("Can't run runclient.py"));
	    }
	    else {
		deferred.resolve(results);
	    }
	    });
    }
    return deferred.promise;
};

function updateClassifiedCount(db,results){
    var deferred = Q.defer();
    var count = 0;
    console.log("3) Running updateClassifiedCount()");
    while(count < results.length){
	db.collection('groups').update({"_id" : new BSON.ObjectID(String(results[count].group_id))},{ $inc : { "classified_count": 1} },
				       function(err,result){ if (err) throw err; })
        console.log("Updated group: " + results[count].group_id)
        db.collection('segment_images').update({"_id" : results[count]._id}, { $set : {"submission_state": "File analysed by net" } }, 
				       function(err,rez){ if (err) throw err; })
    count++;
    }
    if(count >= results.length){
	deferred.resolve(results);
    }
    console.log("Returning from updateClassifiedCount()");
    return deferred.promise;
};

function checkGroupCompletion(db,results){
    var deferred = Q.defer();
    console.log("4) Running checkGroupCompletion()");
    var count = 0;
    while(count < results.length){
	 db.collection('groups').find({"_id" : new BSON.ObjectID(String(results[count].group_id))})
                                .toArray(function(err,toUpdate){
				    if(toUpdate[0].image_count == toUpdate[0].classified_count && toUpdate[0].group_status == "Complete"){ 
					
					    var result_set = ''; 
					    if(toUpdate[0].leaf)   result_set = result_set + ' leaf '   + toUpdate[0].leaf 
					    if(toUpdate[0].flower) result_set = result_set + ' flower ' + toUpdate[0].flower 
					    if(toUpdate[0].fruit)  result_set = result_set + ' fruit '  + toUpdate[0].fruit
					    if(toUpdate[0].entire) result_set = result_set + ' entire ' + toUpdate[0].entire 
				    
					    console.log("Time to exec the combine.py script.")
				   
					    exec("python ./ML/combine.py " + result_set, function(err,stdout,stderro){
						
						if(!err){
						    db.collection('groups').update({"_id": toUpdate[0]._id},{$set: {"classification": stdout, "group_status": "Classified" }}, function(err,res){
							console.log("Classification added to group: " + toUpdate[0]._id)
						    })
						}
						else {
						    console.log("Something went wrong with combine.py. Not update group classification.");
						}
					    }); // exec combine.py complete
					}
				    });
	count++;
    } // end of while()
};


function onError(db,results){

    var count = 0;
    while(count < results.length){
    db.collection('groups').find({"_id" : new BSON.ObjectID(String(results[count].group_id))})
                           .toArray(function(err,toUpdate){
			       
			   db.collection('groups').update({"_id": toUpdate[0]._id},{$set: {"classification": "{ \"radish plant\":0.093 , \"crucifer\":0.084 , \"sweet melon\":0.081 , \"gourd\":0.054 , \"winter squash\":0.042 }" , "group_status": "Classified" }}, function(err,res){
							console.log("Classification added to group: " + toUpdate[0]._id)
						    })
			   });

    count++;
    } // end of while()
}
