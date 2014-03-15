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
var child = require('child_process');

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

// Switch our confFile depending on how environment is set up.
/* istanbul ignore else */
/* Ignored by Istanbul because this ONLY goes one way during TEST and PROD respectively */
if(process.env.NODE_ENV ==='test'){
  /* use the confFile which will have been scoped in the test module above */
  var confFile = module.parent.exports.conf;
}
else{
  var args = process.argv.splice(2); 
  var confFile = args[0];
}

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

/* Start polling mongo */
//routes.groupClassify(db,configArgs,function(){});
var poll = child.fork('./poll.js',configArgs)


/* Enable classify function via post at /classify url */
//app.post('/classify', routes.classify(db));
app.post('/classify', routes.classify(db,configArgs));

// If we are the top module (ie, not testing) then start the app.
/* istanbul ignore if */
/* Ignored for coverage because we only launch app in production */
if (!module.parent) {
  http.createServer(app).listen(app.get('port'), function(){
    console.log('Express server listening on port ' + app.get('port'));
  });
}
