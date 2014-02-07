
/**
 * Module dependencies.
 */

var express = require('express');
var routes = require('./routes');
var http = require('http');
var path = require('path');

// Code to allow connection to mongo
var mongo = require('mongodb');
var monk = require('monk');


// Initialise our variables to store the various database ports and locations
var db_host = ' ';
var db_port = ' ';
var db_database = ' ';

// Store our command line arguments in args.
// Note that:
//           argv[0] is just node and that
//           argv[1] is the path to the *.js

var args = process.argv.splice(2); 

// Store the Environment required
var runEnv = args[0];

// Check what argument we were passed and connect to appropriate DB.

if (!runEnv){
  console.log('No arguments given, I cannot initialise without knowing env vars!');
} 
else if (runEnv === 'dev'){
  db_host = '146.169.44.217';
  db_port = '57017';
  db_database = 'development';
}
else if (runEnv === 'qa'){
  db_host = '146.169.44.217';
  db_port = '57117';
  db_database = 'qualityAssurance';
  console.log('Invalid arguments provided, I cannot initialise!');
  process.exit(1);
}
else if (runEnv === 'prod'){
  db_host = '146.169.44.217';
  db_port = '57217';
  db_database = 'production';
  console.log('Invalid arguments provided, I cannot initialise!');
  process.exit(1);
}
else {
  console.log('Invalid arguments provided, I cannot initialise!');
  process.exit(1);
}

// Tell the user how we started up.

console.log('Starting up with: ' + runEnv + ' parameters!');

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
	uploadDir:path.join('./uploads', runEnv)
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
