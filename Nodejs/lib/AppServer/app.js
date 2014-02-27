/* DEBUG FLAG */

var DEBUG = true;

/**
 * Module dependencies.
 */
var mongo = require('mongodb');
var fs = require('fs');
var express = require('express');
var routes = require('./routes');
var http = require('http');
var path = require('path');
var parse = require('./config_parser');
var async = require('async');
var app = express();


/* Initialise our variables to store the various database ports and locations */
var config = -1;

/* 
* Store our command line arguments in args.
* Note that:
*           argv[0] is just node and that
*           argv[1] is the path to the *.js
*/
var args = process.argv.splice(2); 
var confFile = args[0];
  
console.log("Parsing Config");

try{
  configArgs = parse.parseConfig(confFile);
}
catch (err) {
  console.log('Error during parse: ' + err);
  return -1;
}

if (typeof(configArgs) !== 'object'){
  console.log('Exiting App due to failed parseConfig')
  return -1;
}


/* Code to allow connection to mongo, gets new instance of MongoClient */
var Server = mongo.Server,
  Db = mongo.Db,
  BSON = mongo.BSONPure;


var server = new Server(configArgs.db_host,configArgs.db_port,{auto_reconnect:true, native_parser: true});
db = new Db(configArgs.db_database,server, {safe: true});

//Actually connect to the database.
db.open(function(err, db) {
    if(!err) {
        console.log("Connected to " + configArgs.db_database + " database");
        db.collection('usercollection', {strict:true}, function(err, collection) {
            if (err) {
                console.log("The 'usercollection' collection doesn't exist!");
                return -1;
            }
        });
    }
});


// ALL OF THESE ARE REQUIRED FOR EXPRESS TO WORK!
app.set('port', process.env.PORT || configArgs.appServer_port);
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

/* Retrieve JSON for jobID and handle bad request */
app.get('/job/:job_id', routes.getJob(db));
app.get('/job', routes.getJob(db));


/* Enable upload function via post at /upload url */
app.post('/upload', routes.upload(db,configArgs));

/* Create HTTP Server */
http.createServer(app).listen(app.get('port'), function(){
  console.log('Express server listening on port ' + app.get('port'));
});

