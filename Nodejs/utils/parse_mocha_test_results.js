var fs = require('fs');
var data = fs.readFileSync('./mocha_test_results.json');
var content = JSON.parse(data);
var stats = content.stats;
var failures = content.failures;

console.log('STATISTICS:');
console.log('\n');
console.log('  Start Time:    ' + stats.start);
console.log('  End Time:     ' + stats.end);
console.log('\n');
console.log('    Total number of tests: ' + stats.tests );
console.log('        Passed: '+stats.passes+'  Failed: '+stats.failures+'  Pending: '+stats.pending);
console.log('\n');

if(stats.failures > 0){
	console.log('\nFAILURES:\n');
	console.log(failures);
}
