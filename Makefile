TEST = node_modules/.bin/mocha
TESTS ?= test/*.coffee
#TEST_FLAGS= --debug

test:
	@NODE_ENV=test \
	  ./$(TEST) \
		$(TEST_FLAGS) $(TESTS)


.PHONY: test