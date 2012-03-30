malifiMod= require('../..')
staticHandler= malifiMod.static_handler
mimeWrapper= malifiMod.mime_wrapper
hasAnExtension = malifiMod.utilities.hasAnExtension

# If adding one of the extensions in meta.implied_static_extensions_ to the end
# of the path finds a file, serve the contents of that file
module.exports= (impliedExtensions)->
  implicitTextFileAction= (req,res,next) ->
    try
      malifi = req.malifi
      files = malifi.files
      for ext in malifi.meta[impliedExtensions]
        if files[ext]
          files['']= files[ext]
          return staticHandler(req,res,next,mimeWrapper)
      next()
    catch e
      next(e)
