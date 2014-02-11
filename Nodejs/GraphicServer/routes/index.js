
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
			
			if (req.files.datafile){

				/* TODO synchronously exec the classification script on the command line */


				
				/* output where we saved the file */
			    console.log("req.files is: " + req.files.datafile.path);
			    
		        // Set our collection
		        var collection = db.collection('usercollection');

		        // Submit to the DB
		        collection.update({	        	
		           { "filepath" : filePath },
		           { 
		           		$set: { "submission_state" : "File Submitted from App" },
		            	$set: { "submission_time" : Math.round(new Date().getTime() / 1000) }
		           } 
		        }, 
		        
		        {safe: true}, 
		        
		        function (err, docs) {
		            if (err) {
		                // If it failed, return error
		                res.send("There was a problem adding the information to the database.");
		            }
		            else {
		                // If it worked, return JSON object from collection to App//
		                //res.json(doc);
		            	res.json( { "id" : docs[0]._id });
		            }
		        });
			}
	}
};