var http = require("http");
var run_test_script = require('./exec_testScript').exec_testScript;

var timestamp = Date.now() /1000 |0;

/* http://146.169.44.217:55000 */
http.createServer(function(request,response){ 
	// if the request we just received was a POST request, extract the data from that message and pass it as an argument to the run_test_script function
	if (request.method == 'POST') {
	        var body = '';
	        request.on('data', function (data) {
	            body += data;
	        });
	        request.on('end', function () {
			run_test_script(body);
		});
	        request.on('error', function (e) {
			console.log('Malformed request: ' + e.message);
		});
	}
	response.writeHead(200, {"Content-Type": "text/plain"}); 
	response.write("\n\n\tWelcome to the Plant Recogniser Continuous Integration server;\n\t\t\t Where Testing Is King!!"); 
	response.write("\n\n\t...server start time: " + timestamp);
	response.end();
}).listen(55000);



