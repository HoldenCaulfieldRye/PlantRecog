var mongo = require('mongodb');
var BSON = mongo.BSONPure;
var fs = require('fs');
var restler = require('restler');
var formidable = require ('formidable');
var path = require ('path');
var util = require ('util');



/*
 * GET Job
 */

exports.getJob = function(db) {
    
    return function(req, res){

	// Set our collection
	var collection = db.collection('usercollection');
	
	var job_id = req.params.job_id;
	
	console.log('GET request parameters are: ' + util.inspect(req.params) );
	
	if(req.params){
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
exports.upload = function(db, graphicServer, configArgs) {
    
    return function(req, res) {

	// Make formidable the multipart form parser
	var form = new formidable.IncomingForm()
	form.uploadDir = path.join('./Nodejs/lib/AppServer/uploads', configArgs.db_database)
	form.keepExtensions = true;
    
	// preset wait time at the moment
	var waitTime = 2;
	

	
	/* log the body of this upload */
	form.parse(req, function (err, fields, files) {

	    console.log('POST request body is: \n' + util.inspect({fields: fields, files: files}) );
	
	    filePath = files.datafile.path;
	
	    if (files){
	    
		/* output where we saved the file */
		console.log("FilePath is: \n" + filePath);
	    
		// Set our collection
		var collection = db.collection('usercollection');

		// Submit to the DB
		collection.insert({
		    vm_filepath : filePath,
		    submission_state : "File Submitted from App",
		    submission_time : Math.round(new Date().getTime() / 1000),
		    image_metadata : {
			date : fields.date,
 			latitude : fields.latitude,
			longitude : fields.longitude
		    },
		    image_segment : fields.segment 
		},
                 {safe: true}, 
                 function (db_err, docs) {
		     if (db_err) {
			 // If it failed, return error
			 res.send("There was a problem adding the information to the database.");
		     }
		     else {
			 // If it worked, return JSON object from collection to App//
		         res.json( { "id" : docs[0]._id });
		         
			 // Send the image over to the classifier
			 restler.post(graphicServer + "/classify", {
			     multipart: true,
			     data: {
				 _id: docs[0]._id,
				 datafile: restler.file(files.datafile.path, null, files.datafile.size, null, "image/jpeg")
			     }
			 }).on("complete", function(data) {
			     console.log("GraphicServer response: \n" + util.inspect(data) );
			 });
			 
		     }
		 });
		
		
	    }
	})
    };
};
