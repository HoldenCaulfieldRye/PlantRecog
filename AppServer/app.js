
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
var db = monk('localhost:55513/apptest1')

var app = express();

// all environments
app.set('port', process.env.PORT || 3000);
app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'jade');
app.use(express.favicon());

app.use(express.bodyParser({ 
	keepExtensions: true,
	uploadDir:'./public/images'
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
