/*

    TO-DO: Need to consolidate all code (Graphic and App servers) and export them from this one place.
           Then any where in the project that we need a Graphic/App Server function, just 'require' this file

*/


// App modules
var app = require('./AppServer/app.js');
module.exports.app = app;
var app_parse = require('./AppServer/config_parser/index.js');
module.exports.app_parse = app_parse;
var app_routes = require('./AppServer/routes/index.js');
module.exports.app_routes = app_routes;


// Graphic modules
var graphic = require('./GraphicServer/graphic.js');
module.exports.graphic = graphic;
var graphic_parse = require('./GraphicServer/config_parser/index.js');
module.exports.graphic_parse = graphic_parse;
var graphic_routes = require('./GraphicServer/routes/index.js');
module.exports.graphic_routes = graphic_routes; 
