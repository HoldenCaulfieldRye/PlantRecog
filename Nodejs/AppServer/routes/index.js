
/*
 * GET home page.
 */

exports.index = function(req, res){
  res.render('index', { title: 'Express' });
};


exports.upload = function(db) {
	
	return function(req, res) {
		
		//setTimeout(function() {
			
			/* log the body of this upload */
			console.log(req.body);
			
			filePath = req.files.datafile.path;
			
			if (req.files.datafile){
				
				/* output where we saved the file */
			    console.log("req.files is: " + req.files.datafile.path);
			    
		        // Set our collection
		        var collection = db.collection('usercollection');

		        // Submit to the DB
		        collection.insert({
		            "filepath" : filePath,
		            "submission_state" : "File Submitted from App",
		            "submission_time" : Math.round(new Date().getTime() / 1000)
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