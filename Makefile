TESTS = test/*.js
REPORTER = dot

test:
	@NODE_ENV=test 
	mocha \
         --reporter $(REPORTER) \
         --require should \
         $(TESTS)


.PHONY: test