# does a file with one of the given extensions exist?

fs = require('fs')

isFile= (name,foundCB)->
  fs.stat name, (err,stats)->
    foundCB(!err && stats.isFile())

module.exports= hasAnExtension= (name,extensions,foundCB)->
  i= -1
  looper= (found)->
    return foundCB(name+extensions[i]) if found
    i+= 1
    return foundCB(false) unless i<extensions.length
    isFile(name+extensions[i],looper)
  looper(false) #initiate the process