REPORTER = json

test:
	@NODE_ENV=test mocha --reporter $(REPORTER) > mocha_test_results.json

test-w:
	@NODE_ENV=test mocha \
    		--reporter $(REPORTER) \
    		--growl \
    		--watch

test-cov: lib-cov
	@PLANT_COV=1 $(MAKE) test REPORTER=json-cov > coverage.json

lib-cov:
	@jscoverage lib lib-cov

.PHONY: test test-w
