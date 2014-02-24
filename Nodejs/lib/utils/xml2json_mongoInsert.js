var fs = require('fs'),
    xml2js = require('xml2js'),				//ensure the xml2js package has been installed 'npm install xml2js'
    MongoClient = require('mongodb').MongoClient;	//ensure the node.js mongodb driver is installed 'npm install mongodb'
var exec=require('child_process').exec;

var collection = 'plants',				//the name of the collection we wish to insert into
    database   = 'development',				//the name of the database we wish to use
    mongod     = 'mongodb://146.169.44.217:55517/',	//host and port of MongoDB server
    conn       = mongod + database;			//connection details for MongoClient.connect

var parser = new xml2js.Parser();

// CHANGE THIS ACCORDINGLY!!! They should ideally be passed via a config file
var NUM_PHOTOS = 100000;			//the number of photos we wish to attempt to convert and save to DB
var IMAGE_DB_PATH = '/data2/ImageNet/train/';	//filesystem directory where image meta-data is stored

var synsets = exec('ls -1 ' + IMAGE_DB_PATH);
console.log(synsets);
//var NUM_SYNSETS = ;

/*
// connect to mongod server, read xml files, parse into json, make some tweaks and insert into collection
MongoClient.connect(conn, function(err, db) {
	if(err) console.log(err);
	for(var j = 1; j <= NUM_SYNSETS; j++){	//iterate through NUM_PHOTOS on disk...image xml's are named 1.xml -> <NUM_PHOTOS>.xml
	  var synset = synsets[j];
	   for(var i = 1; i <= NUM_PHOTOS; i++){	//iterate through NUM_PHOTOS on disk...image xml's are named 1.xml -> <NUM_PHOTOS>.xml
		///var file = IMAGE_DB_PATH + i + '.xml';
		var file = IMAGE_DB_PATH + synset + '/' + synset + '_' + i + '.xml';
		if (fs.existsSync(file)) {	//check that the file exists first...do synchronously to ensure we subsequently read and parse the correct file
			console.log('file exists ' + file);
			//read xml file
			var data = fs.readFileSync(file);
			//parse data into json
			parser.parseString(data, function (err, result) {
			  // make some tweaks to result 	
			  //var document = result.Image;
			  //document.FileName = [ IMAGE_DB_PATH + document.FileName ]; 					
			  var document = result.root.meta_data;
			  // add bucket information at this stage
			  (function(doc){  
				var res = db.collection('buckets').find({species : doc.Species[0] }, {limit: 1, fields : {bucket : 1, _id : 0}});
				res.nextObject(function(err,item){
					if(err) console.log('error retrieving bucket information' + err);
					// TO-DO: add a check for null bucket!!!
					document.Bucket = [ item.bucket ];
					console.log(document);
			  		// insert doc into mongo collection 
			  		db.collection(collection).insert(
			  		  document, 
			    		  {safe: true}, 
			    		  function(err, records){
			      		    if(err) console.log('error inserting document into MongoDB' + err);
			    		  }
			  		);
				});
			  })(document);
			});
		}
	   };
	};
});

*/

