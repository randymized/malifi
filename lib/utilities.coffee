fs = require('fs')

isFileSync= (name)->
  try
    fs.statSync(name).isFile()
  catch e
    throw e unless e.code == 'ENOENT'
    false

module.exports=
  # is the given name that of a regular file?
  isFileSync: isFileSync

  # Would adding the proper extension to the given name find a file whose extension
  # suggested that it could be a module?
  isModuleSync: (name)->
    isFileSync(name+'.js') || isFileSync(name+'.coffee')|| isFileSync(name+'.json')