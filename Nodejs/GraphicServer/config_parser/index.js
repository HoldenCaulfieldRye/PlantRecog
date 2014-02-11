/*
 * Config file parsing function.
 * It got quite long so I've abstracted it.
 */

var fs = require('fs');


exports.parseConfig = function(confFile){
  
  /* Things to seek our environment variables with*/
  /* TODO: remove vars which are not relevant to graphic02 */
  var dbSeekString = '# NODE_INI: db_database = ';
  var dbHostSeekString = '# NODE_INI: db_host = ';
  var dbPortSeekString = 'port = ';
  var classifierHostSeekString = '# NODE_INI: graphic_http_host = ';
  var classifierHttpPortSeekString = '# NODE_INI: graphic_http_port = ';
  var appServerHttpPortSeekString = '# NODE_INI: vm_http_port = ';
  
  var db_host = -1;
  var db_port = -1;
  var db_database = -1;
  var classifier_host = -1;
  var classifier_port = -1;
  var appServer_port = -1;
  
  var configArgs = {};
  
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
    throw 'Invalid conf file provided, I cannot initialise!';
  }
  
  /* Return our configuration object */
  configArgs.db_port = db_port;
  configArgs.db_host = db_host;
  configArgs.db_database = db_database;
  configArgs.classifier_host = classifier_host;
  configArgs.classifer_port = classifier_port;
  configArgs.appServer_port = appServer_port;
  
  return configArgs;
  
};