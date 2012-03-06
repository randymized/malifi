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
