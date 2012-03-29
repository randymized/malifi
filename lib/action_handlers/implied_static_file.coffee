staticHandler= require('../static_handler')
mimeWrapper= require('../mime_wrapper')
hasAnExtension = require('../utilities').hasAnExtension

# If adding one of the extensions in meta._implied_static_extensions to the end
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
