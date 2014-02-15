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



fs.stat("sample.jpg", function(err, stats) {
    restler.post("http://localhost:55581/classify", {
        multipart: true,
        data: {
            "_id": "52f916b400d9bbcf42b87b01",
            "datafile": restler.file("sample.jpg", null, stats.size, null, "application/octet-stream")
        }
    }).on("complete", function(data) {
        console.log(data);
    });
});