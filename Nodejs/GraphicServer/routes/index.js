var mongo = require('mongodb');
var BSON = mongo.BSONPure;
var ObjectId = require('mongodb').ObjectID;


/*
 * GET home page.
 */

exports.index = function(req, res){
  res.render('index', { title: 'Express' });
};


exports.classify = function(db) {
	
	return function(req, res) {
				
			/* log the body of this upload */
			console.log(req.body);
			
			filePath = req.files.datafile.path;
			collection = db.collection('usercollection');
			
				/* TODO synchronously exec the classification script on the command line */
			    //exec("python ../../../ML/runtest.py entire ../sample1.jpg", function(err,stdout,stderr){
				//console.log("Image classified");
			    //});

				
				/* output where we saved the file */
			    console.log("req.body._id is: " + req.body._id);
			    
		        // Find our document
		          collection.findAndModify(	        	
		              { '_id': new BSON.ObjectID(req.body._id)},
		              [],
		              { $set : { 
		                "submission_state" : "Image classified",
		                "submission_time" : Math.round(new Date().getTime() / 1000),
		                "graphic_filepath": filePath}
		              },
		              {}, 
		              function (err,doc) {
		                if (err) {
		                  //If it failed, return error
		                  console.log(err);
		                  res.send("There was a problem adding the information to the database.");
		                }
		                else {
		                 // If it worked, return JSON object from collection to App//
		                  //res.json(doc);
		                  res.json(doc);
		                }
		              });
	};
};
