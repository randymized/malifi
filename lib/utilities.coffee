fs = require('fs')

isFile= (name,cb)->
  try
    fs.stat name, (err,stats)->
      cb(!err && stats.isFile())

isFileSync= (name)->
  try
    fs.statSync(name).isFile()
  catch e
    throw e unless e.code == 'ENOENT'
    false

extensions= ['.json','.coffee','.js']

isModule= (name,cb)->
  i= extensions.length
  looper= (found)->
    return cb(true) if found
    return cb(false) unless i
    i-= 1
    isFile(name+extensions[i],looper)
  looper(false)

module.exports=
  # is the given name that of a regular file?
  isFile: isFile
  isFileSync: isFileSync

  # Would adding the proper extension to the given name find a file whose extension
  # suggested that it could be a module?
  isModule: isModule
  isModuleSync: (name)->
    isFileSync(name+'.js') || isFileSync(name+'.coffee')|| isFileSync(name+'.json')