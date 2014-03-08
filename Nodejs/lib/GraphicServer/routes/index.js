var mongo = require('mongodb');
var BSON = mongo.BSONPure;
var ObjectId = require('mongodb').ObjectID;
var exec = require('child_process').exec;
var formidable = require ('formidable');
var path = require ('path');
var util = require ('util');
var mkdirp = require('mkdirp');


exports.index = function(req, res){
  res.render('index', { title: 'Express' });
};

/*
 * GET Classification	
 */

exports.classify = function(db,configArgs) {
	
	var form = new formidable.IncomingForm();
        //form.uploadDir = path.join('./Nodejs/lib/GraphicServer/uploads', configArgs.db_database);
        //form.keepExtensions = true;

	return function(req, res) {
				
			form.parse(req, function(err, fields, files){
				
				// Determine where to save the file
				fileLocation = path.join('./Nodejs/lib/GraphicServer/uploads', configArgs.db_database, fields.group_id)
             			console.log("fileLocation: " + fileLocation);
				// Create the folder in which to save the file
				mkdirp.sync(fileLocation,function(err){
				    if(err) console.error("Error creating group directory: " + err)
				    else console.log("Successfully created folder: " + fileLocation)
				})

				// Save the file
       	    		        form.uploadDir = path.join('./Nodejs/lib/GraphicServer/uploads', configArgs.db_database, fields.group_id)
				form.keepExtensions = true;	

				console.log('POST request body is: \n' + util.inspect({fields: fields, files: files}) );

	   			filePath = files.datafile.path;	
	   			fileName = files.datafile.name;
			        //id = files.datafile
			        console.log('Filename: ' + fileName);
			
	        	if(files){

	        		// Output where we saved the file 
					console.log("FilePath is: \n" + filePath);
	    
					// Set our collection
					var collection = db.collection('segment_images');
			    
					collection.findAndModify(	        	
				    	    { '_id': new BSON.ObjectID(fields.segment_id) },	                                              [], 
				            { $set : { "submission_state" : "File received by graphic" }
		                },
			    	 
			    	    {'new': true}, 
		              
				        function (err,doc) {
				        	if (err) {
				                //If it failed, return error
						console.log("Error adding information to db"); 
				                console.log(err);
				                res.send("There was a problem adding the information to the database.");
				            }
				            else {
				            	// If it worked, return JSON object from collection to App//
						console.log("db updated: file received by graphic");                                              
					        // Reply to app server
				            	res.json("File received by graphic");
				            }
					});
				}
			});
	};
};

/*
// This script should be launched on graphic server startup
exports.groupClassify = function(db, configArgs){

	var components = [ "leaf", "flower", "branch", "fruit", "bark" ]
	var numComponents = components.length;
	var collection = db.collection('usercollection');

	// Will loop forever
	for (var i = 0 ;; i = (i++)%numComponents){

		// Sync
		var classification = collection.find({ "submission_state": "File Submitted from App", "image_segment" : components[i] }).sort({"submission_time": 1}).limit(128);
		runNet(classification,components[i]);

	}
}

// STEP 1.5: 'Pack' images into format (JSON?) which can be parsed by John

// STEP 2: Receive results and append to DB
// I assume that John returns the same structure as in runtest.py
// Iterate over the collection-type object using javascript, executing a MongoDB procedure each time

var runNet = function(classification, type, callback){

	return function(req, res){

		exec('python ML/runtest.py ' + type + ' ' + classification, function(err,stdout,stderr){

			if(err !== null){
				console.log('exec error:' + err);
			}
			else {
				n = result.length;

				for(var i = 0; i < n; i++) {

					id = results[i][_id];
					classification_leaf = results[i][classification]
					collection.findAndModify(
						{ '_id': new BSON.ObjectID(id) },
						{ $set: { "status" : "Component classified" } }
					)
				}
			}
		});
		// end of exec

	res.json(doc);

	}
}
*/

					// Query our net	
					//exec('python ML/runtest.py entire ../../../../' + filePath, function(err,stdout,stderr){
					    
					//    console.log('stdout: ' + stdout);
					//    console.log('stderr: ' + stderr);
					    
					//    if(err !== null){
					//		console.log('exec error:' + err);
					//    }
					    
					//    var output = stdout.toString();
					//    var json_obj = output.substring(output.search('{'),output.search('}')+1);
					    
					//    console.log('json_obj: ' + json_obj);

