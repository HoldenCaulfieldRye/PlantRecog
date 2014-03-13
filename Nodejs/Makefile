REPORTER = json

install:
	npm install --production

dev-install:
	npm install

test:
	@NODE_ENV=test ./node_modules/.bin/istanbul cover ./node_modules/.bin/_mocha ./test/ 

graphic_test:
	@NODE_ENV=test ./node_modules/.bin/istanbul cover ./node_modules/.bin/_mocha ./test/graphicRoutesTest.js

graphic_instantiation:
	@NODE_ENV=test ./node_modules/.bin/istanbul cover ./node_modules/.bin/_mocha ./test/graphicTest.js	

.PHONY: test graphic_test
