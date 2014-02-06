var http = require("http");
var run_test_script = require('./exec_testScript').exec_testScript;

var timestamp = Math.round(+new Date()/1000);

/* http://146.169.44.217:55000 */
http.createServer(function(request,response){ 
	if (request.method == 'POST') {
	        var body = '';
	        request.on('data', function (data) {
	            body += data;
	        });
	        request.on('end', function () {
			run_test_script(body);
		});
	}
	response.writeHead(200, {"Content-Type": "text/plain"}); 
	response.write("\n\n\tWelcome to the Plant Recogniser Continuous Integration server;\n\t\t\t Where Testing Is King!!"); 
	response.write("\n\tStart-Timestamp: " + timestamp);
	response.end();
}).listen(55000);



