fs = require('fs')
staticHandler= require('../static_handler')
utilities= require('../utilities')
mimeWrapper= require('../mime_wrapper')

# if a static file is requested, return it
module.exports= textAction= (req,res,next) ->
  try
    malifi = req.malifi
    meta = malifi.meta
    path = malifi.path
    if !meta._allowed_static_extensions? || utilities.nameIsInArray(path.extension,meta._allowed_static_extensions)
      fs.stat path.full, (err, stat) =>
        try
          return next() if err
          staticHandler(req,res,next,mimeWrapper)
        catch e
          next(e)
    else
      next()
  catch e
    next(e)
