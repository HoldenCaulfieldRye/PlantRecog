var mongo = require('mongodb');
var BSON = mongo.BSONPure;
var exec = require('child_process').exec;
var async = require('async');
var Q = require('q');

var db_host = process.argv[2];
var db_port = process.argv[3];
var db_database = process.argv[4];

console.log("db_host: " + db_host + ", db_port: " + db_port + ", db_database: " + db_database);

connectToMongo(db_host,db_port,db_database, mainLoop);     // returns the database connection
	
                function mainLoop(db){
		    
                     getNewImages(db)     // returns all the relevant image documents
			.then(function(docs,err){
			    return runClient(docs)
			    .then(function(){
				return updateClassifiedCount(db,docs)
				.then(function(){
				    return checkGroupCompletion()
					.then(function(check){
					    return Q.delay(500)
						.then(function(){
						    return mainLoop(db);
				   		})
					})
				})
			    })
			})

/*			    
			    if(docs.length != 0) {
				return runClient(docs) // also returns the image documents
 				    .then(function(docs){
					console.log(docs)
					return updateClassifiedCount(db,docs) // also returns the image documents
//					   .then(function(docs){
//					    });
				    })
			  

				    .fail(function(err){
				    // runclient.py failed
					console.log("runclient.py failed. Retrying runClient()");
					return runClient(docs) // also returns the image documents
 					    .then(function(docs){
						console.log(docs)
						return updateClassifiedCount(db,docs) // also returns the image documents
					//	   .then(function(docs){
					//		return checkGroupCompletion(db,docs);
						
					//	    });
					    })
					    .fail(function(err){
						console.log("runclient.py has failed twice - append dummy data")
						return onError(db,results)
					    })
				    });
			    }  // end of docs.length != 0 test
	
			});

		    .then(checkGroupCompletion())
		       .then(function(check){
			   console.log("checked for group completion");
			   mainDeferred.resolve("done")
		       });
*/		
		  //  return mainDeferred.promise;
		  //  .then(function(foo){
		//	mainLoop(db);
			
		  //  })
		//setTimeout(mainLoop(db),2000);
		}
		//}, 2000) // end of setInterval(


/******************** function definitions *************************/

	
function connectToMongo(host,port,database,callback){
        console.log("Running connectToMongo()");
  	mongoClient = new mongo.MongoClient(new mongo.Server(host, port), {native_parser: true});
  	mongoClient.open(function(err, mongoClient){
		db = mongoClient.db(database);
		callback(db)
	});
};

function getNewImages(db) {
	var deferred = Q.defer();
        //console.log("Running getNewImages() ");
	db.collection('segment_images').find({"submission_state" : "File received by graphic"})
				       .sort({"submission_time": -1})
	                               .limit(128)
				       .toArray(function(err,docs){
					   if(docs.length > 0){
					       var date = new Date();
					       console.log(date);
                      			       console.log("Return #" + docs.length + " documents.")
                      			   }
					   if(err){
					       deferred.reject(new Error(err))}
					   else{
					       //console.log("resolving promise")
				               deferred.resolve(docs);
					   }
					});

    //console.log("Returning from getNewImages()")   
    return deferred.promise;

};

function runClient(results){
    var deferred = Q.defer();
    //console.log("Running runClient()");
    var count = 0;
    var str = "";
    if(results.length != 0){
    while(count < results.length){
	str += str + " " + results[count].graphic_filepath;
	count++;
    }
    
    if(count >= results.length){
	console.log("python ./ML/runclient.py entire " + str)
	exec('python ./ML/runclient.py entire' + str, function(error,stdout,sterror){
	    if(error){
		console.log("Error running runclient.py:" + error);
		deferred.reject(new Error("Can't run runclient.py"));
	    }
	    else {
		deferred.resolve(results);
	    }
	    });
    }
    }
    else{
	deferred.resolve(results);
    }
    return deferred.promise;
};

function updateClassifiedCount(db,results){
    var deferred = Q.defer();
    var count = 0; 
    //console.log("Running updateClassifiedCount()");
    if(results != 0){
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
    }
    else{
	deferred.resolve(results);
    }
    //console.log("Returning from updateClassifiedCount()");
    return deferred.promise;
};

function checkGroupCompletion(){
    var deferred = Q.defer();
    //console.log("Running checkGroupCompletion()");

	 db.collection('groups').find({"group_status" : "Complete"})
	               .toArray(function(err,toUpdate){

			   if(toUpdate.length != 0){

			       updateGroupWhenComplete(toUpdate,toUpdate.length-1)
			       //.then(function(){
			//	   deferred.resolve("resolved")
			//       })
			       .fail(function(){
				   deferred.resolve("resolved")
			       })
			         
			   }
			   else{
			       //console.log("no groups to update")
			       deferred.resolve("resolved")
			   }
	       }); //end of toArray


  return deferred.promise
};


function updateGroupWhenComplete(toUpdate,i){
    
    //console.log("Running updateGroupWhenComplete() " + i);
    
    var deferred = Q.defer();
    
    if(i >= 0 && i < toUpdate.length){
	
	//var deferred2 = Q.defer();

	var result_set = '';
	if(toUpdate[i].leaf)   result_set = result_set + ' leaf '   + toUpdate[i].leaf
	if(toUpdate[i].flower) result_set = result_set + ' flower ' + toUpdate[i].flower
	if(toUpdate[i].fruit)  result_set = result_set + ' fruit '  + toUpdate[i].fruit
	if(toUpdate[i].entire) result_set = result_set + ' entire ' + toUpdate[i].entire

	console.log("Time to exec the combine.py script.")
	exec("python ./ML/combine.py " + result_set, function(err,stdout,stderro){

	    if(!err){
		db.collection('groups').update({"_id": new BSON.ObjectID(String(toUpdate[i]._id))},{$set: {"classification": stdout, "group_status": "Classified" }}, function(err,res){
		    
		    console.log("** Classification added to group: " + toUpdate[i]._id + " **")
		    deferred.resolve("resolved");
		})
            }
            else {
		console.log("Something went wrong with combine.py. Not updated group classification.");
		deferred.resolve("error");
	    }
	}); // exec combine.py complete                                                         
	
    }
    else{	
	deferred.reject("rejected"); 	
    }

    return deferred.promise.then(function(){
	return updateGroupWhenComplete(toUpdate,i-1);
    })

}


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
