###
# Given an array of names, returns true if the given name is in the array.
# As an optimizing side-effect for further tests against the array, a regular
# expression is attached to the array that will actually perform the test.
###

RegExp.escape ?= (str) ->
  specials = new RegExp("[.*+?|()\\[\\]{}\\\\]", "g"); # .*+?|()[]{}\
  return str.replace(specials, "\\$&")

createArrayRegexp= (arr)->
  a= (RegExp.escape(n) for n in arr)
  arr.regexp ?= new RegExp('((' + a.join(')|(') + '))$')

module.exports= nameIsInArray= (name,arr)->
    return if arr
      (arr.regexp ?= createArrayRegexp(arr)).test(name)
    else
      false