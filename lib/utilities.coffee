fs = require('fs')

isFile= (name,foundCB)->
  fs.stat name, (err,stats)->
    foundCB(!err && stats.isFile())

isFileSync= (name)->
  try
    fs.statSync(name).isFile()
  catch e
    throw e unless e.code == 'ENOENT'
    false

moduleExtensions= ['.js','.coffee','.json']

hasAnExtension= (name,extensions,foundCB)->
  i= -1
  looper= (found)->
    return foundCB(extensions[i]) if found
    i+= 1
    return foundCB(false) unless i<extensions.length
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
  isModule: (name,foundCB)->
    hasAnExtension(name,moduleExtensions,foundCB)
  isModuleSync: (name)->
    return true for ext in moduleExtensions when isFileSync(name+ext)
    false