REPORTER = json

install:
	npm install --production

dev-install:
	npm install

test:
	./node_modules/.bin/istanbul cover ./node_modules/.bin/_mocha ./test/

test-cov: lib-cov
	@PLANT_COV=1; $(MAKE) test REPORTER=json-cov

lib-cov:
	@if [ -d lib-cov ] ; then rm -r lib-cov ; fi
	@jscoverage -v --exclude ./AppServer/node_modules/ --exclude ./GraphicServer/node_modules lib lib-cov

.PHONY: test test-cov lib-cov 
