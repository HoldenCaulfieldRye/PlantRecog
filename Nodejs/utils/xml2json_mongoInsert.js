var fs = require('fs'),
    xml2js = require('xml2js'),
	MongoClient = require('mongodb').MongoClient,	//ensure the relevant packages have been installed and node.js mongo driver installed
	format = require('util').format;

var table = 'plants';
var parser = new xml2js.Parser();			//ensure the xml2js package has been installed 'npm install xml2js'
var mongod = 'mongodb://127.0.0.1:27017/'	//host and port of MongoDB server

// connect to mongod server, read xml files, parse into json, make some tweaks and insert into collection
MongoClient.connect(mongod + table, function(err, db) {
	
	if(err) throw err;

	//read xml file...use full path 
	fs.readFile(__dirname + '/sample.xml', function(err, data) {
		//parse data into json
		parser.parseString(data, function (err, result) {
			console.dir(result);
			console.log('Done');

			var document // = make some tweaks to result 	

			// insert doc into mongo collection 
			db.collection(table).insert(
				document, 
				{safe: true}, 
				function(err, records){
				 console.log("Record added as "+records[0]._id);
				}); 
			});
	});
});

