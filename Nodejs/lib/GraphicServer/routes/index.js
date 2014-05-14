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
			    
			        // I'm sorry
			        var absoluteFilePath = "/homes/sd3112/GroupProject/group-project-master/Nodejs/lib/GraphicServer/uploads" + "/" + configArgs.db_database + "/" + fields.group_id + "/" + files.datafile.name;
			        var segment = fields.image_segment
			        var obj = {}
                                obj[segment] = absoluteFilePath
                       
	        	if(files){
	    
			                /* update the mongo groups document with segment time and path */    
			                db.collection('groups').update( { "_id" : new BSON.ObjectID(fields.group_id) } , { $set: obj }, function(err,results){
					    if(err) console.log("Error updating groups collection: " + err)
					})
			
			                // Set our collection
					var collection = db.collection('segment_images');
			                
					collection.findAndModify(	        	

				    	 { '_id': new BSON.ObjectID(fields.segment_id) },	                                              
					    [], 
				            { $set : { "submission_state" : "File received by graphic", "graphic_filepath": "/homes/sd3112/GroupProject/group-project-master/Nodejs/lib/GraphicServer/uploads" + "/" + configArgs.db_database + "/" + fields.group_id + "/" + files.datafile.name } },

			    	 
			    	    {'new': true}, 
		              
				        function (err,doc) {
				            if (err) {
				                //If it failed, return error
						console.log("Error adding information to db: " + err); 
				                res.send("There was a problem adding the information to the database.");
				            }
				            else {
				            	// If it worked, return JSON object from collection to App
						console.log("db updated: file received by graphic");                                              
					        // Reply to app server
						res.json("File received by graphic");

				            }

					});
				}
			});
	};
};



