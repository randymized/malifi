fs = require('fs')

module.exports=
  isFileSync: (name)->
    try
      fs.statSync(name).isFile()
    catch e
      throw e unless e.code == 'ENOENT'
      false