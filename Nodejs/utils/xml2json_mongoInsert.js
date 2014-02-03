var fs = require('fs'),
	xml2js = require('xml2js'),
	MongoClient = require('mongodb').MongoClient,	//ensure the relevant packages have been installed and node.js mongo driver installed
	format = require('util').format;

var table = 'plants';
var parser = new xml2js.Parser();			//ensure the xml2js package has been installed 'npm install xml2js'
var mongod = 'mongodb://127.0.0.1:27017/';	//host and port of MongoDB server

var NUM_PHOTOS = 55000;
var imagedb_path = '/data/db2/';

// connect to mongod server, read xml files, parse into json, make some tweaks and insert into collection
MongoClient.connect(mongod + table, function(err, db) {

	if(err) throw err;

	for(var i = 0; i < NUM_PHOTOS; i++){

		var file = imagedb_path + i + '.xml';

		if (fs.existsSync(file)) {

			//read xml file
			fs.readFile(file, function(err, data) {
				
				//parse data into json
				parser.parseString(data, function (err, result) {
					console.dir(result);
					console.log('Done');
	
					// make some tweaks to result 	
					var document = ...; 
	
					// insert doc into mongo collection 
					db.collection(table).insert(
						document, 
						{safe: true}, 
						function(err, records){
						console.log("Record added as "+records[0]._id);
					}); 
				
				});
			
			});
		
		};
	};

});

