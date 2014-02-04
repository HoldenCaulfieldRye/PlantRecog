var fs = require('fs'),
    xml2js = require('xml2js'),				//ensure the xml2js package has been installed 'npm install xml2js'
    MongoClient = require('mongodb').MongoClient,	//ensure the node.js mongodb driver is installed 'npm install mongodb'
    format = require('util').format;			//is this needed?

var table = 'plants',
    mongod = 'mongodb://146.169.44.217:57017/',	//host and port of MongoDB server
    conn = mongod + table;
    parser = new xml2js.Parser();
/*
// on VM server
var NUM_PHOTOS = 15030;
var IMAGE_DB_PATH = '/home/gerardh/data/';
*/
// on graphic02
//var NUM_PHOTOS = 47815;
var NUM_PHOTOS = 100000;
var IMAGE_DB_PATH = '/home/gerardh/data/';
//var IMAGE_DB_PATH = '/data2/leafdb/train/';

// connect to mongod server, read xml files, parse into json, make some tweaks and insert into collection
MongoClient.connect(conn, function(err, db) {
	if(err) console.log(err);
	for(var i = 1; i <= NUM_PHOTOS; i++){
		var file = IMAGE_DB_PATH + i + '.xml';
		if (fs.existsSync(file)) {
			console.log('file exists ' + file);
			//read xml file
			var data = fs.readFileSync(file);
			//parse data into json
			parser.parseString(data, function (err, result) {
			  // make some tweaks to result 	
			  var document = result.Image;
			  document.FileName = [ IMAGE_DB_PATH + document.FileName ]; 					
			  console.log(document);
			  // add taxon tree at this stage ???
			  // document.TaxonTree = ['Plant', 'Flowering Plant'];
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
//figure out a way to close the connection when finished...can't do it currently because parseString is an async function...needs to be sync i think...unless there are other options i am unaware of/yet to experiment with
//	db.close();
});



