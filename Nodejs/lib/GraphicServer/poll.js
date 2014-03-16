var mongo = require('mongodb');
var exec = require('child_process').exec;
var async = require('async');
var db_host = process.argv[2];
var db_port = process.argv[3];
var db_database = process.argv[4];

console.log("db_host: " + db_host + " db_port: " + db_port + " db_database: " + db_database);

try{    
  mongoClient = new mongo.MongoClient(new mongo.Server(db_host, db_port), {native_parser: true});
  mongoClient.open(function(err, mongoClient){
      if (err) {
	  console.log("Error opening database")
      throw err;
      }
    // Connect to the relevant database
      db = mongoClient.db(db_database);

      var components = ["leaf", "flower", "fruit", "entire", "x"];
      var numComponents = components.length;
      var i = 0;

      async.forever(function(callback){
                      db.collection('segment_images').find({"submission_state" : "File received by graphic", "image_segment": components[i]}).toArray(function(err,docs){
			                 console.log("retrieved doc in whilst loop");
                       console.log("Return #" + docs.length + " documents.")
                       console.log(docs[0].vm_filepath);
                       i = (++i)%numComponents;
			                 setImmediate(callback);
		                  });
                    },
                    function(err){
                      console.log("An error occured");
                    }    
                  )

  });

}
catch(err){
  console.log('Error connecting to Database: ' + err);
  return -1;
}

/*
var components = [ "leaf", "flower", "fruit", "entire" ]
var numComponents = components.length;

try{
    var collection = db.collection('segment_images');
}catch(err){
    console.log("Error connecting to segment_images collection")
    console.log(err)
}
    collection.find({"submission_state":"File Submitted from App"}).each(function(err,docs){
    console.log("retrieved record in poll.js");
    console.log(docs[0].vm_filepath);
});
*/