malifiMod= require('../..')
staticStreamer= malifiMod.static_streamer
hasAnExtension = malifiMod.has_an_extension

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
          return staticStreamer(req,res,next)
      next()
    catch e
      next(e)
