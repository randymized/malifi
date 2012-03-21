staticHandler= require('../static_handler')
mimeWrapper= require('../mime_wrapper')
hasAnExtension = require('../utilities').hasAnExtension

# If adding one of the extensions in meta._implied_static_extensions to the end
# of the path finds a file, serve the contents of that file
module.exports= ()->
  implicitTextFileAction= (req,res,next) ->
    try
      fullpath = req.malifi.path.full
      hasAnExtension fullpath+'.', req.malifi.meta._implied_static_extensions, (found)=>
        if found
          try
            req.malifi.path.full= found
            staticHandler(req,res,next,mimeWrapper)
          catch e
              next(e)
        else
          next()
    catch e
      next(e)
