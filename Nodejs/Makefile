REPORTER = json

test:
	@NODE_ENV=test; /usr/bin/mocha --reporter $(REPORTER) > mocha_test_results.json

test-cov: lib-cov
	@PLANT_COV=1; $(MAKE) test REPORTER=json-cov

lib-cov:
	@if [ -d lib-cov ] ; then rm -r lib-cov ; fi
	@jscoverage -v --exclude ./AppServer/node_modules/ --exclude ./GraphicServer/node_modules lib lib-cov

.PHONY: test test-cov lib-cov 
