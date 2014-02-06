
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
			
			filePath = req.files.filename.path;
			
			if (req.files.filename){
				
				/* output where we saved the file */
			    console.log("req.files is: " + filePath);
			    
		        // Set our collection
		        var collection = db.get('usercollection');

		        // Submit to the DB
		        collection.insert({
		            "filepath" : filePath,
		            "submission_state" : "File Submitted from App",
		            "submission_time" : Math.round(new Date().getTime() / 1000)
		        }, 
		        
		        function (err, doc) {
		            if (err) {
		                // If it failed, return error
		                res.send("There was a problem adding the information to the database.");
		            }
		            else {
		                // If it worked, return JSON object from collection to App//
		                //res.json(doc);
		            	res.json( { "id" : doc._id })
		            }
		        })
			}
		//},5000);
	}
}
