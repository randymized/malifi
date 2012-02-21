fs = require('fs')
staticHandler= require('../static_handler')
utilities= require('../utilities')
mime = require('mime')

mimeWrapper= (path,cb)->
  fs.stat path, (err, stat) =>
    if err
      cb(err)
    else
      type = mime.lookup(path)
      cb(null,mime.lookup(path))

# if a .txt file is requested, return it
module.exports= textAction= (pass) ->
  if !@meta._allowed_static_extensions? || utilities.nameIsInArray(@path.extension,@meta._allowed_static_extensions)
    staticHandler.call(this,mimeWrapper)
  else
    pass()
