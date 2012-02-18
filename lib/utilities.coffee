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

moduleExtensions= ['.js','.coffee','.json']

hasAnExtension= (name,extensions,cb)->
  i= -1
  looper= (found)->
    return cb(extensions[i]) if found
    i+= 1
    return cb(false) unless i<extensions.length
    isFile(name+extensions[i],looper)
  looper(false) #initiate the process

module.exports=
  # is the given name that of a regular file?
  isFile: isFile
  isFileSync: isFileSync

  # does a file with one of the given extensions exist?
  hasAnExtension: hasAnExtension

  # Would adding the proper extension to the given name find a file whose extension
  # suggested that it could be a module?
  isModule: (name,cb)->
    hasAnExtension(name,moduleExtensions,cb)
  isModuleSync: (name)->
    return true for ext in moduleExtensions when isFileSync(name+ext)
    false