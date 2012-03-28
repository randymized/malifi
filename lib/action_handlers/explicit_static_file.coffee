fs = require('fs')
staticHandler= require('../static_handler')
utilities= require('../utilities')
mimeWrapper= require('../mime_wrapper')

# if a static file is requested (including its extension), return it
module.exports= (allowedExtensions)->
  textAction= (req,res,next) ->
    try
      malifi = req.malifi
      path = malifi.path
      files = malifi.files
      allowed = malifi.meta[allowedExtensions]
      if (!allowed? || utilities.nameIsInArray(path.extension,allowed)) && files['']
        staticHandler(req,res,next,mimeWrapper)
      else
        next()
    catch e
      next(e)
