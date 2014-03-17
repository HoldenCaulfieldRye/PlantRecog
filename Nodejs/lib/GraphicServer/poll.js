var mongo = require('mongodb');
var BSON = mongo.BSONPure;
var exec = require('child_process').exec;
var async = require('async');

var db_host = process.argv[2];
var db_port = process.argv[3];
var db_database = process.argv[4];
var str = '';

console.log("db_host: " + db_host + " db_port: " + db_port + " db_database: " + db_database);

try{    
  mongoClient = new mongo.MongoClient(new mongo.Server(db_host, db_port), {native_parser: true});
  mongoClient.open(function(err, mongoClient){
      if (err) {
	  console.log("Error opening database")
      throw err;
      }
       // Connect to the relevant database
      db = mongoClient.db(db_database);

      var components = ["leaf", "flower", "fruit", "entire", "x"];
      var numComponents = components.length;
      var i = 0;

      async.forever(function(callback){
          db.collection('segment_images').find({"submission_state" : "File received by graphic", "image_segment": components[i]}).sort({"submission_time": -1}).limit(128).toArray(function(err,docs){
			                // console.log("retrieved doc in whilst loop");
                      console.log("Return #" + docs.length + " documents.")
	                    var count = 0;
              	      str = '';
              	      if(docs.length != 0){	  
              		      async.whilst( function(){ return count < docs.length },
              				                function(callback){
                            				    if(docs[count].graphic_filepath){
                            					     str = str + " " + docs[count].graphic_filepath;
                            				    }
//                            				    console.log("str: " + str);
							    count = count + 1;
                            				    //console.log("count = " + count);
                            				    setImmediate(callback);
                            				},
              				                function(err){
							    console.log('str: ' + str);
							    
							    
                      exec('python ./ML/run.py ' + components[i] + ' ' + str, function(error, stdout, stderr){
                        //  console.log('stdout: ' + stdout);
                          //console.log('stderr: ' + stderr);
                         if(error != null){
                         console.log('exec error: ' + error);
                          } 
                          else{
                            // update all the relevant mongo entries
							    var count2 = 0;
                                  async.whilst( function(){ return count2 < docs.length },
                                                function(callback){
                                                  if(docs[count2].graphic_filepath){
                                                     db.collection('groups').update({"_id" : new BSON.ObjectID(docs[count2].group_id)},{ $inc : { "classified_count": 1} },function(err,result){ 
							 if (err) throw err;
							 console.log("result: " + result);
						     })
                                                      console.log("Updated group: " + docs[count2].group_id)
                                                  }
						  count2 = count2 + 1;
                                                  setImmediate(callback);
                                              },
                                                function(err){
						    var count3 = 0;
						    async.whilst(function(){ return count3 < docs.length },			  
								 function(callback){ 
								      db.collection('groups').find().toArray(function(err,results){
								      if(results){
									  if(results[count3].image_count == results[count3].classified_count){
									  
									      console.log("exec-ing")

									      //exec("python combine.py )
									  
									  }
									  else{
									      console.log("not exec-ing")

									  }
								      }
								    })
								     count3 = count3+1;
								  setImmediate(callback);
							          },
								  function(err){
								      
								      // update the relevant groups with a 'classification' field
								      
								  }
						    )
						}
                                 )
                          }
                      });

		});






          	      }
        });
	  	         
       // Put these in the exec callback?
       i = (++i)%numComponents;
	     setTimeout(callback,5000);
      },  
      
        function(err){
            console.log("An error occured");
        }    
      )

  });

}
catch(err){
  console.log('Error connecting to Database: ' + err);
  return -1;
}

/*
var components = [ "leaf", "flower", "fruit", "entire" ]
var numComponents = components.length;

try{
    var collection = db.collection('segment_images');
}catch(err){
    console.log("Error connecting to segment_images collection")
    console.log(err)
}
    collection.find({"submission_state":"File Submitted from App"}).each(function(err,docs){
    console.log("retrieved record in poll.js");
    console.log(docs[0].vm_filepath);
});
*/
