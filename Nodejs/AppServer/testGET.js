/**
 * New node file
 */

var request = require('request');
var FormData = require('form-data');
var fs = require('fs');
var path = require('path');
var restler = require('restler');

//var form = new FormData();
//form.append("folder_id", "0");
//form.append("filename", fs.createReadStream(path.join(__dirname, "headshot.jpg")));
//
//form.getLength(function(err, length){
//  if (err) {
//    return requestCallback(err);
//  }
//
//  var r = request.post("http://posttestserver.com/post.php", requestCallback);
//  r._form = form;     
//  r.setHeader('content-length', length);
//
//});
//
//function requestCallback(err, res, body) {
//  console.log(body);
//}



restler.get("http://localhost:55580/job/52ff86ddb844830a533f2b40", {
  multipart: true,
  data: {
    bla: "bla"
  }
}).on("complete", function(data) {
  console.log(data);
});