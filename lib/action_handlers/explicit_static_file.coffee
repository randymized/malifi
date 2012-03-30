fs = require('fs')
malifiMod= require('../..')

# if a static file is requested (including its extension), return it
module.exports= (allowedExtensions)->
  textAction= (req,res,next) ->
    try
      malifi = req.malifi
      path = malifi.path
      files = malifi.files
      allowed = malifi.meta[allowedExtensions]
      if (!allowed? || malifiMod.name_is_in_array(path.extension,allowed)) && files['']
        malifiMod.static_streamer(req,res,next,malifiMod.mime_wrapper)
      else
        next()
    catch e
      next(e)
