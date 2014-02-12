var fs = require('fs'),
    xml2js = require('xml2js'),				//ensure the xml2js package has been installed 'npm install xml2js'
    MongoClient = require('mongodb').MongoClient,	//ensure the node.js mongodb driver is installed 'npm install mongodb'

var table = 'plants',				//the name of the collection we wish to insert into
    mongod = 'mongodb://146.169.44.217:57017/',	//host and port of MongoDB server
    conn = mongod + table;			//connection details for MongoClient.connect
    parser = new xml2js.Parser();

var NUM_PHOTOS = 100000;			//the number of photos we wish to attempt to convert and save to DB
var IMAGE_DB_PATH = '/home/gerardh/data/';	//filesystem directory where image meta-data is stored

// connect to mongod server, read xml files, parse into json, make some tweaks and insert into collection
MongoClient.connect(conn, function(err, db) {
	if(err) console.log(err);
	for(var i = 1; i <= NUM_PHOTOS; i++){	//iterate through NUM_PHOTOS on disk...image xml's are named 1.xml -> <NUM_PHOTOS>.xml
		var file = IMAGE_DB_PATH + i + '.xml';
		if (fs.existsSync(file)) {	//check that the file exists first...do synchronously to ensure we subsequently read and parse the correct file
			console.log('file exists ' + file);
			//read xml file
			var data = fs.readFileSync(file);
			//parse data into json
			parser.parseString(data, function (err, result) {
			  // make some tweaks to result 	
			  var document = result.Image;
			  document.FileName = [ IMAGE_DB_PATH + document.FileName ]; 					
			  console.log(document);
			  // add bucket information at this stage
			  bucket = db.collection('buckets').find({ species : document.Species } , { bucket : 1, _id : 0 });
			  document.Bucket = [ bucket ];
			  // insert doc into mongo collection 
			  db.collection(table).insert(
			    document, 
			    {safe: true}, 
			    function(err, records){
			      if(err) console.log(err);
			    }
			  ); 
			});
		}
	};
});



