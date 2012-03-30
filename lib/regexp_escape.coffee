# Once require-d, RegExp is patched to include an escape function that
# will escape any characters that have special meaning in a regular expression.
#
# This module exports nothing.  It exists only for its side-effect
RegExp.escape ?= (str) ->
  specials = new RegExp("[.*+?|()\\[\\]{}\\\\]", "g"); # .*+?|()[]{}\
  return str.replace(specials, "\\$&")
