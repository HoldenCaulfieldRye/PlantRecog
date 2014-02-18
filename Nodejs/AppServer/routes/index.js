var mongo = require('mongodb');
var BSON = mongo.BSONPure;
var fs = require('fs');
var restler = require('restler');

/*
 * GET Job
 */

exports.getJob = function(db) {
  
    return function(req, res){

      // Set our collection
      var collection = db.collection('usercollection');
      
      var job_id = req.params.job_id;
      
      console.log(req.params);
      
      if(job_id){
        console.log('Retrieving job: ' + job_id);
        try{
          collection.findOne({'_id':new BSON.ObjectID(job_id)}, function(err, item) {
              res.send(item);
          });
        }
        catch(err){
          console.log(err);
          res.send("You did not submit a valid JobID!");
        }
      }
      else{
        res.send("You did not submit a JobID");
      }
    };
};

/*
 * POST Image
 */
exports.upload = function(db, graphicServer) {
	
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
		            "vm_filepath" : filePath,
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
		            	
		                // Send the image over to the classifier
		                restler.post(graphicServer + "/classify", {
		                  multipart: true,
		                  data: {
		                    "_id": docs[0]._id,
		                    "datafile": restler.file(req.files.datafile.path, null, req.files.datafile.size, null, "application/octet-stream")
		                  }
		                }).on("complete", function(data) {
		                  console.log(data);
		                });
		              
		            }
		        });
		        

			}
	};
};