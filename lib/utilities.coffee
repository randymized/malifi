fs = require('fs')

RegExp.escape ?= (str) ->
  specials = new RegExp("[.*+?|()\\[\\]{}\\\\]", "g"); # .*+?|()[]{}\
  return str.replace(specials, "\\$&")

isFile= (name,foundCB)->
  fs.stat name, (err,stats)->
    foundCB(!err && stats.isFile())

hasAnExtension= (name,extensions,foundCB)->
  i= -1
  looper= (found)->
    return foundCB(name+extensions[i]) if found
    i+= 1
    return foundCB(false) unless i<extensions.length
    isFile(name+extensions[i],looper)
  looper(false) #initiate the process

createArrayRegexp= (arr)->
  a= (RegExp.escape(n) for n in arr)
  arr.regexp ?= new RegExp('((' + a.join(')|(') + '))$')

module.exports=
  # does a file with one of the given extensions exist?
  hasAnExtension: hasAnExtension

  # Given an array of names, returns true if the given name is in the array.
  # As an optimizing side-effect for further tests against the array, a regular
  # expression is attached to the array that will actually perform the test.
  #
  nameIsInArray: (name,arr)->
    return if arr
      (arr.regexp ?= createArrayRegexp(arr)).test(name)
    else
      false