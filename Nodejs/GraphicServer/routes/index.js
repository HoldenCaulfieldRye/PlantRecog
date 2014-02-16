var mongo = require('mongodb');
var BSON = mongo.BSONPure;
var ObjectId = require('mongodb').ObjectID;
var exec = require('child_process').exec;

/*
 * GET home page.
 */

exports.index = function(req, res){
  res.render('index', { title: 'Express' });
};

exports.classify = function(db) {
	
	return function(req, res) {
				
			/* log the body of this upload */
			console.log('req.body._id: ' + req.body._id);
			
			filePath = req.files.datafile.path;
	                collection = db.collection('usercollection');
			
			exec('python ML/runtest.py entire ../../../' + filePath, function(err,stdout,stderr){
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
		                  //res.json(doc);
				  console.log("db updated");
		                  res.json(doc);
		                }
		              });
			});  
	};
};
