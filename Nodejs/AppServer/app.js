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
var app = express();

/* Code to allow connection to mongo, gets new instance of MongoClient */
var mongoClient = mongo.MongoClient;
var db = -1;

/* Things to seek our environment variables with*/
var dbSeekString = '# NODE_INI: db_database = ';
var dbHostSeekString = '# NODE_INI: db_host = ';
var dbPortSeekString = 'port = ';
var classifierHostSeekString = '# NODE_INI: graphic_http_host = ';
var classifierHttpPortSeekString = '# NODE_INI: graphic_http_port = ';
var appServerHttpPortSeekString = '# NODE_INI: vm_http_port = ';


/* Initialise our variables to store the various database ports and locations */
var db_host = -1;
var db_port = -1;
var db_database = -1;
var classifier_host = -1;
var classifier_port = -1;
var appServer_port = -1;

/* 
* Store our command line arguments in args.
* Note that:
*           argv[0] is just node and that
*           argv[1] is the path to the *.js
*/
var args = process.argv.splice(2); 

/* Store the Environment required */
var confFile = args[0];
var confArray = [];

/* Check what argument we were passed and parse the config file. */

if (!confFile){
  console.log('No arguments given, I cannot initialise without a .conf');
  process.exit(1);
} 

/* try and parse the file (use Sync readFile), catch any error */
try {
  confArray = fs.readFileSync(confFile).toString().split('\n');  
}
catch (err) {
  console.log('Error parsing confFile: ' + err);
  process.exit(1);
}

/* Extract our configuration variables */
for(var i in confArray){
  
  if(confArray[i].substring(0, dbSeekString.length) === dbSeekString){
    db_database = confArray[i].substring(dbSeekString.length);
    console.log('Database to use is: ' + db_database);
  }

  if(confArray[i].substring(0, dbHostSeekString.length) === dbHostSeekString){
    db_host = confArray[i].substring(dbHostSeekString.length);
    console.log('Database Host is: ' + db_host);
  }
  
  if(confArray[i].substring(0, dbPortSeekString.length) === dbPortSeekString){
    db_port = confArray[i].substring(dbPortSeekString.length);
    console.log('Database Port is: ' + db_port);
  }
  
  if(confArray[i].substring(0, classifierHostSeekString.length) === classifierHostSeekString){
    classifier_host = confArray[i].substring(classifierHostSeekString.length);
    console.log('Classifier Host is: ' + classifier_host);
  }
  
  if(confArray[i].substring(0, classifierHttpPortSeekString.length) === classifierHttpPortSeekString){
    classifier_port = confArray[i].substring(classifierHttpPortSeekString.length);
    console.log('Classifier HTTP Port is: ' + classifier_port);
  }
  
  if(confArray[i].substring(0, appServerHttpPortSeekString.length) === appServerHttpPortSeekString){
    appServer_port = confArray[i].substring(appServerHttpPortSeekString.length);
    console.log('Port to use is: ' + appServer_port);
  }
  
}

/* Exit if we could not configure */
if(db_port === -1 || db_host === -1 || db_database === -1 ||
    classifier_host === -1 || classifier_port === -1 || appServer_port === -1){
  console.log('Invalid conf file provided, I cannot initialise!');
  process.exit(1);
}


// Tell the user how we started up.

console.log('Starting up database connection now!');

// Actually connect to the database.
  mongoClient.connect('mongodb://' + db_host + ':' + db_port + '/' + db_database, function(err, db){
    if (err) throw err;
  });



// all environments
app.set('port', process.env.PORT || 3000);
app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'jade');
app.use(express.favicon()); 

// Set up our options related to uploads. We want to put images to each Env
// in a different folder.
app.use(express.bodyParser({ 
	keepExtensions: true,
	uploadDir:path.join('./Nodejs/AppServer/uploads', db_database)
	})
);

app.use(express.logger('dev'));
app.use(express.json());
app.use(express.urlencoded());
app.use(express.methodOverride());
app.use(express.cookieParser('your secret here'));
app.use(express.session());



app.use(app.router);




/* makes public subdirectory appear as if it were the tld, so it can be 
 * accessed like http://localhost:3000/images  
 */
app.use(express.static(path.join('./public')));

// development only
if ('development' == app.get('env')) {
  app.use(express.errorHandler());
}

/* Routes to follow on URL */
app.get('/', routes.index);


/* Enable upload function via post at /upload url */
app.post('/upload', routes.upload(db));

/* Create HTTP Server */
http.createServer(app).listen(app.get('port'), function(){
  console.log('Express server listening on port ' + app.get('port'));
});
