fs = require('fs')
staticHandler= require('../static_handler')
utilities= require('../utilities')
mimeWrapper= require('../mime_wrapper')

# if a static file is requested (including its extension), return it
module.exports= (metaname)->
  textAction= (req,res,next) ->
    try
      malifi = req.malifi
      meta = malifi.meta
      path = malifi.path
      if !meta[metaname]? || utilities.nameIsInArray(path.extension,meta[metaname])
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
