var mongo = require('mongodb');
var BSON = mongo.BSONPure;
var ObjectId = require('mongodb').ObjectID;
var exec = require('child_process').exec;
var formidable = require ('formidable');
var path = require ('path');
var util = require ('util');
var mkdirp = require('mkdirp');
var fs = require('fs');

exports.classify = function(db,configArgs) {

	return function(req, res) {
				
			var form = new formidable.IncomingForm();

	        // Switch our uploadDIR depending on how this is being run.
	        /* istanbul ignore else */
	        /* Ignored by Istanbul because this ONLY goes one way during TEST and PROD respectively */
	        if(process.env.NODE_ENV ==='test'){
	            form.uploadDir = path.join('./lib/GraphicServer/uploads', configArgs.db_database);
	        }
	        else{
	            form.uploadDir = path.join('./Nodejs/lib/GraphicServer/uploads', configArgs.db_database);
	        }
	        form.keepExtensions = true;

	        try{
				form.on('file', function(field, file) {
	            //rename the incoming file to the file's name
	            	fs.renameSync(file.path, form.uploadDir + "/" + file.name);
				})
			} catch (err) {
				res.send("Unable to rename file")
				return err;
			}

			form.parse(req, function(err, fields, files){

				// Determine where to save the file
				try{
					groupLocation = path.join(form.uploadDir, fields.group_id)
             		fileLocation = path.join(form.uploadDir, files.datafile.name)
             		mkdirp.sync(groupLocation)

				} catch(err){
					res.send("Insufficient arguments supplied")
					return err;
				}
				
             	try{
   	    			fs.renameSync(fileLocation, groupLocation + "/" +  files.datafile.name)
		    	} catch(err){	
		    		res.send("Could not rename file")
		    	return err;
		   		}  

                console.log('POST request body is: \n' + util.inspect({fields: fields, files: files}) );

	   			filePath = files.datafile.path;	
	   			fileName = files.datafile.name;

	        	if(files){
	    
					// Set our collection
					var collection = db.collection('segment_images');
			                
					collection.findAndModify(	        	

				    	 { '_id': new BSON.ObjectID(fields.segment_id) },	                                              
					    [], 
				            { $set : { "submission_state" : "File received by graphic", "graphic_filepath": groupLocation + "/" + files.datafile.name } },

			    	 
			    	    {'new': true}, 
		              
				        function (err,doc) {
				        	if (err) {
				                //If it failed, return error
								console.log("Error adding information to db: " + err); 
				                res.send("There was a problem adding the information to the database.");
				            }
				            else {
				            	// If it worked, return JSON object from collection to App//

							console.log("db updated: file received by graphic");                                              
					        // Reply to app server
				            res.json("File received by graphic");

				            }

					});

			    /* Test code */

			    var result = collection.find({"submission_state": "File Submitted from App"}).toArray(function(err,docs){
				console.log("retrieved records in routes/index.js");
				console.log(docs[0].vm_filepath);
});

			    
			   


				}
			});
	};
};


// This script should be launched on graphic server startup
/*
exports.groupClassify = function(db, configArgs){

	var components = [ "leaf", "flower", "fruit", "entire" ]
	var numComponents = components.length;
	var collection = db.collection('segment_images');

	// Will loop forever
	for (var i = 0 ;; i = (++i)%numComponents){	    
		   
	    collection.find({ "submission_state": "File Submitted from App", "image_segment" : components[i] }, { "graphic_location": 1}).sort({"submission_time": 1}).limit(128).toArray(function(err,docs){
		console.log("foo");

		if(err){
		    console.log("Error: " + err);
		}
		
		if(!docs){
		    console.log("No results");
		    
		}
		
					       console.log(docs)
	    })
            
	   
		//runNet(classification,components[i]);

	}
}

*/

// STEP 1.5: 'Pack' images into format (JSON?) which can be parsed by John

// STEP 2: Receive results and append to DB
// I assume that John returns the same structure as in runtest.py
// Iterate over the collection-type object using javascript, executing a MongoDB procedure each time
/*
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


