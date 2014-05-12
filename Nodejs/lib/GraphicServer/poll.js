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

      var components = ["leaf", "flower", "fruit", "entire"];
      var numComponents = components.length;
      var i = 0;

      async.forever(function(callback){
          db.collection('segment_images').find({"submission_state" : "File received by graphic", "image_segment": components[i]}).sort({"submission_time": -1}).limit(128).toArray(function(err,docs){
                      console.log("Return #" + docs.length + " documents.")
	              var count = 0;
              	      str = '';
              	      if(docs.length != 0){	  
              		      async.whilst( function(){ return count < docs.length },
              				                function(callback){
                            				    if(docs[count].graphic_filepath){
                            					     str = str + " " + docs[count].graphic_filepath;
                            				    }
							    console.log("graphic filepath: " + docs[count].graphic_filepath);
							    count = count + 1;
                            				    setImmediate(callback);
                            				},
              				                function(err){
							    console.log('str: ' + str);
							    
		              // Note: this is nested in the first async.whilst
                              //if(docs.length != 0){
                              exec('python ./ML/runclient.py ' + components[i] + ' ' + str, function(error, stdout, stderr){
			      console.log('exec-ing runclient.py');	  
                              console.log('stdout: ' + stdout);
                              console.log('stderr: ' + stderr);
                              if(error != null){
				  console.log('runclient.py exited with : ' + error);
                              } 
                              else{

                              // Update all the relevant mongo entries - increment classified_count by 1
		              var count2 = 0;
                              async.whilst( function(){ return count2 < docs.length },
                                            function(callback){
						  //console.log("we think the group_id is: " + docs[count2].group_id)
                                                  if(docs[count2].graphic_filepath){
                                                     db.collection('groups').update({"_id" : new BSON.ObjectID(String(docs[count2].group_id))},{ $inc : { "classified_count": 1} },function(err,result){ 
							 if (err) throw err;
					             })
                                                     console.log("Updated group: " + docs[count2].group_id)
                                                     db.collection('segment_images').update({"_id" : docs[count2]._id}, { $set : {"submission_state": "File analysed by net" } }, function(err,rez){
							 if (err) throw err;
						     })						     
						  }
						  count2 = count2 + 1;
                                                  setTimeout(callback,1000);
                                                 },
                                            function(err){
	                      })}} )})} });
			      // Iterate through groups whose images we have analysed and check whether images_count = classified_count 
			      //var count3 = 0;
                              //var flag = true;
			      //async.whilst(function(){ return flag },			  
			     	//	   function(callback){
					        //if(docs[count3].graphic_filepath){
				//		    console.log("docs.length: " + docs.length);
					            //console.log("docs[count3].group_id: " + docs[count3].group_id )
						    //console.log("results[0].image_count: " + result)
						    //console.log("")
						    //console.log("")
						    //db.collection('groups').find({"_id" : new BSON.ObjectID(String(docs[count3].group_id))}).toArray(function(err,results){
	  console.log("Searching for groups to combine");
						    db.collection('groups').find({"group_status":"Complete"}).toArray(function(err,results){

							console.log("Combining: " + results.length);

							if(!err){
                                                        var process = true;
							for(var j = 0; j < results.length;){
							console.log("still running!" + j);
							//if(!err && results.length == 1){
                                                        if (process){
                                                        process = false;
							if(results[j].image_count == results[j].classified_count){ // && results[0].group_status == "Complete"){	  
                                                            				
							    var result_set = '' 
							    if(results[j].leaf)   result_set = result_set + ' leaf '   + results[j].leaf 
							    if(results[j].flower) result_set = result_set + ' flower ' + results[j].flower 
							    if(results[j].fruit)  result_set = result_set + ' fruit '  + results[j].fruit
							    if(results[j].entire) result_set = result_set + ' entire ' + results[j].entire 
							    
							    console.log("Time to exec the combine.py script.")
							    console.log("Passing this string to combine.py:" + result_set)
							    exec("python ./ML/combine.py " + result_set, function(err,stdout,stderro){
								console.log(stdout);
								console.log("group id: " + results[j]._id);
								if(!err){
								    db.collection('groups').update({"_id": results[j]._id},{$set: {"classification": stdout, "group_status": "Classified" }}, function(err,res){
								       console.log("Classification added to group: " + results[j]._id)
									j++;
      									process = true;
								    })
								}
								else{
								console.log("Unable to combine images");
								j++;
                                                                process = true;
								}
							     }) // end of exec	  
							}
                                                        
							else{
							    console.log("not exec-ing");
							    j++;
                                                            process = true;
							}
							}    
							}
						    }
						})
					        //count3 = count3+1;
					        
					       //flag = false;
					       //setTimeout(callback,5000);
					
					        	   
					  
					  //function(err){  
			        
       i = (++i)%numComponents;
       setTimeout(callback,10000);
         
                               },

        function(err){
            console.log("An error occured");
        }    
		   ); // end of async forever
			     });
                          }
                        // });
		        // });
          	      //}
        //});
	  	         
       // Put these in the exec callback?

        
      
      //}

  //});

//}
catch(err){
  console.log('Error connecting to Database: ' + err);
  return -1;
}


