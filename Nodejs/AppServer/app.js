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

/* Code to allow connection to mongo */
var mongo = require('mongodb');
var monk = require('monk');


/* Initialise our variables to store the various database ports and locations */
var db_host = -1;
var db_port = -1;
var db_database = -1;

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
  
  var dbSeekString = '# NODE_INI: db_database = ';
  var hostSeekString = '# NODE_INI: db_host = ';
  var portSeekString = 'port = ';
  
  if(confArray[i].substring(0, dbSeekString.length) === dbSeekString){
    db_database = confArray[i].substring(dbSeekString.length);
    console.log('Database to use is: ' + db_database);
  }

  if(confArray[i].substring(0, hostSeekString.length) === hostSeekString){
    db_host = confArray[i].substring(hostSeekString.length);
    console.log('Host to connect to is: ' + db_host);
  }
  
  if(confArray[i].substring(0, portSeekString.length) === portSeekString){
    db_port = confArray[i].substring(portSeekString.length);
    console.log('Port to use is: ' + db_port);
  }
  
}

/* Exit if we could not configure */
if(db_port === -1 || db_host === -1 || db_database === -1){
  console.log('Invalid conf file provided, I cannot initialise!');
  process.exit(1);
}


// Tell the user how we started up.

console.log('Starting up database connection now!');

// Actually connect to the database.
var db = monk(db_host + ':' + db_port + '/' + db_database);


var app = express();

// all environments
app.set('port', process.env.PORT || 3000);
app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'jade');
app.use(express.favicon()); 

// Set up our options related to uploads. We want to put images to each Env
// in a different folder.
app.use(express.bodyParser({ 
	keepExtensions: true,
	uploadDir:path.join('./uploads', db_database)
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
