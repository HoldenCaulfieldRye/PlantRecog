/* DEBUG FLAG */

var DEBUG = true;

/**
 * Module dependencies.
 */
var fs = require('fs');
var express = require('express');
var routes = require('./routes');
var http = require('http');
var path = require('path');
var mongo = require('mongodb');
var parse = require('./config_parser');
var async = require('async');
var app = express();

/* Code to allow connection to mongo, gets new instance of MongoClient */
var mongoClient = mongo.MongoClient;
var db = -1;


/* Initialise our variables to store the various database ports and locations */
var config = -1;

/* 
* Store our command line arguments in args.
* Note that:
*           argv[0] is just node and that
*           argv[1] is the path to the *.js
*/

var args = process.argv.splice(2); 
//var confFile = args[0];
var confFile = '../env/graphic_dev_env.conf'  

console.log("Parsing Config");

try{
  //configArgs = parse.parseConfig(confFile);
  configArgs = parse.parseConfig(confFile);
}
catch (err) {
  console.log('Error during parse: ' + err);
  return -1;
}

//Actually connect to the database.

try{    
  mongoClient = new mongo.MongoClient(new mongo.Server(configArgs.db_host, configArgs.db_port), {native_parser: true});
  mongoClient.open(function(err, mongoClient){if (err) throw err;});
  db = mongoClient.db(configArgs.db_database);
}
catch(err){
  console.log('Error connecting to Database: ' + err);
  return -1;
}



// ALL OF THESE ARE REQUIRED FOR EXPRESS TO WORK!
app.set('port', process.env.PORT || configArgs.classifier_port);
app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'jade');
app.use(express.favicon()); 
app.use(express.logger('dev'));
app.use(express.json());
app.use(express.urlencoded());
app.use(express.methodOverride());
app.use(express.cookieParser('your secret here'));
app.use(express.session());
app.use(app.router);


/* makes public subdirectory appear as if it were the tld, so it can be 
 * accessed like http://localhost:3000/  
 */
app.use(express.static(path.join('./public')));

// development only
if ('development' == app.get('env')) {
  app.use(express.errorHandler());
}

/* Routes to follow on URL */
//app.get('/', routes.index);
app.get('/', routes.index);

/* Enable classify function via post at /classify url */
//app.post('/classify', routes.classify(db));
app.post('/classify', routes.classify(db,configArgs));

/* Create HTTP Server */
http.createServer(app).listen(app.get('port'), function(){
  console.log('Express server listening on port ' + app.get('port'));
});
