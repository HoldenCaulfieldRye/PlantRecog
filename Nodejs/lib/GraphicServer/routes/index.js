var mongo = require('mongodb');
var BSON = mongo.BSONPure;
var ObjectId = require('mongodb').ObjectID;
var exec = require('child_process').exec;
var formidable = require ('formidable');
var path = require ('path');


exports.index = function(req, res){
  res.render('index', { title: 'Express' });
};

/*
 * GET Classification	
 */

exports.classify = function(db,configArgs) {
	
	var form = new formidable.IncomingForm();
	form.uploadDir = path.join('./Nodejs/lib/GraphicServer/uploads', configArgs.db_database);
	form.keepExtensions = true;	

	return function(req, res) {
				
			form.parse(req, function(err, fields, files){

				console.log('POST request body is: \n' + util.inspect({fields: fields, files: files}) );

	   			filePath = files.datafile.path;	

				/* pre-formidable code */
				//console.log('req.body._id: ' + req.body._id);			
				//filePath = req.files.datafile.path;
	        	//collection = db.collection('usercollection');
			
	        	if(files){

	        		// Output where we saved the file 
					console.log("FilePath is: \n" + filePath);
	    
					// Set our collection
					var collection = db.collection('usercollection');

					// Query our net	
					exec('python ML/runtest.py entire ../../../../' + filePath, function(err,stdout,stderr){
					    
					    console.log('stdout: ' + stdout);
					    console.log('stderr: ' + stderr);
					    
					    if(err !== null){
							console.log('exec error:' + err);
					    }
					    
					    var output = stdout.toString();
					    var json_obj = output.substring(output.search('{'),output.search('}')+1);
					    
					    console.log('json_obj: ' + json_obj);
					    
					    collection.findAndModify(	        	
				              { '_id': new BSON.ObjectID(req.body._id)}, /* new BSON.  '52ff886b27d625b55344093f' */
				              [],
				              { $set : { 
				                  "submission_state" : "Image classified",
		          	                  "graphic_filepath": filePath,
		                                  "classification": json_obj}
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
									console.log("db updated");
					            	res.json(doc);
					            }
					        });
					});  
				}
			});
	};
};
