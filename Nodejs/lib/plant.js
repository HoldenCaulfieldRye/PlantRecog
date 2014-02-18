/*

    TO-DO: Need to consolidate all code (Graphic and App servers) and export them from this one place.
           Then any where in the project that we need a Graphic/App Server function, just 'require' this file

*/

/*
// App modules
var app = require('./AppServer/app.js');
module.exports.app = app;
var app_config = require('./AppServer/config_parser/index.js');
module.exports.app_config = app_config;
var app_routes_index = require('./AppServer/routes/index.js');
module.exports.app_routes_index = app_routes_index;
*/


// Graphic modules
var graphic = require('./GraphicServer/graphic.js');
module.exports.graphic = graphic;
var graphic_config = require('./GraphicServer/config_parser/index.js');
module.exports.graphic_config = graphic_config;
var graphic_routes_index = require('./GraphicServer/routes/index.js');
module.exports.graphic_routes_index = graphic_routes_index; 
