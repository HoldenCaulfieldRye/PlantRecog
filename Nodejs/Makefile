REPORTER = json

install:
	npm install --production

dev-install:
	npm install

request_test:
	@NODE_ENV=test ./node_modules/.bin/istanbul cover ./node_modules/.bin/_mocha ./test/Request

worker_test:
	@NODE_ENV=test ./node_modules/.bin/istanbul cover ./node_modules/.bin/_mocha ./test/Worker

all_test:
	@NODE_ENV=test ./node_modules/.bin/istanbul cover ./node_modules/.bin/_mocha ./test/**/*.js


.PHONY: request_test worker_test all_test
