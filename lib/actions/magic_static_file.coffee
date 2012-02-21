fs = require('fs')
staticHandler= require('../static_handler')
utilities= require('../utilities')
mime_magic = require('mime-magic')

# if a .txt file is requested, return it
module.exports= textAction= (pass) ->
  if !@meta._allowed_static_extensions? || utilities.nameIsInArray(@path.extension,@meta._allowed_static_extensions)
    debugger
    staticHandler.call(this,mime_magic.fileWrapper)
  else
    pass()
