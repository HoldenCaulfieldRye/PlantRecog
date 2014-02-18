REPORTER = json

test:
	@NODE_ENV=test; /usr/bin/mocha --reporter $(REPORTER) > mocha_test_results.json

test-cov: lib-cov
	@PLANT_COV=1; $(MAKE) test REPORTER=json-cov

lib-cov:
	@jscoverage -v --exclude ./AppServer/node_modules/ lib lib-cov

.PHONY: test test-cov lib-cov 
