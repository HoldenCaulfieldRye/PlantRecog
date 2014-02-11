var fs = require('fs');
var data = fs.readFileSync('./mocha_test_results.json');
var content = JSON.parse(data);
var stats = content.stats;
var failures = content.failures;


console.log('\tCode Coverage Summary:');
console.log('\t\tcoverage: ' + content.coverage + '%\thits: ' + content.hits + '\tmisses: ' + content.misses + '\t sloc: ' + content.sloc);
console.log('\n');
console.log('\tSTATISTICS:');
console.log('\n');
console.log('\tStart Time:    ' + stats.start);
console.log('\tEnd Time:      ' + stats.end);
console.log('\n');
console.log('\tTotal number of tests: ' + stats.tests );
console.log('\t\tPassed: '+stats.passes+'  Failed: '+stats.failures+'  Pending: '+stats.pending);
console.log('\n');

if(stats.failures > 0){
	console.log('\n\tFAILURES:\n');
	console.log(failures);
}
