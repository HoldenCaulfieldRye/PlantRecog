var mongo = require('mongodb');
var configArgs = process.argv[2];

try{    
  mongoClient = new mongo.MongoClient(new mongo.Server(configArgs.db_host, configArgs.db_port), {native_parser: true});
  mongoClient.open(function(err, mongoClient){if (err) throw err;});
  db = mongoClient.db(configArgs.db_database);
}
catch(err){
  console.log('Error connecting to Database: ' + err);
  return -1;
}


var components = [ "leaf", "flower", "fruit", "entire" ]
var numComponents = components.length;
var collection = db.collection('segment_images');

// Will loop forever
for (var i = 0 ;; i = (++i)%numComponents){	    
	
	console.log("foo");

    collection.find({ "submission_state": "File Submitted from App", "image_segment" : components[i] }, { "graphic_location": 1}).sort({"submission_time": 1}).limit(128).toArray(function(err,docs){
	
		if(err){
		    console.log("Error: " + err);
		}
		
		if(!docs){
		    console.log("No results");
		    
		}
		
		console.log(docs)

	    })
        
}