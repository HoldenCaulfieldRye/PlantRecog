var spawn = require('child_process').spawn;
var content, git_url, git_ref;

var exec_testScript = function(data){
	/* parse contents of json message and extract the git_url and git_ref */
	content = JSON.parse(data);
	git_url = content.repository.url;
	git_ref = content.ref;
	
	/* spawn the unit test script passing args extracted from json message */
	var ssh = spawn('./testSuite.sh', [' ' + git_url, git_ref]);
	/* redirect stdout and stderr of spawned process back to parent */
	ssh.stdout.on('data', function (out) {
	   process.stdout.write(out);
	});  
	ssh.stderr.on('data', function (err) {
	   process.stdout.write(err);
	});  
}

module.exports.exec_testScript = exec_testScript;
