REPORTER = json

install:
	npm install --production

dev-install:
	npm install

test:
	@NODE_ENV=test ./node_modules/.bin/istanbul cover ./node_modules/.bin/_mocha ./test/ 

test-cov: lib-cov
	@PLANT_COV=1; $(MAKE) test REPORTER=json-cov

lib-cov:
	@rm -r lib-cov
	@jscoverage -v --exclude ./AppServer/node_modules/ lib lib-cov

.PHONY: test test-cov lib-cov 
