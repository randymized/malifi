staticHandler= require('../static_handler')
mimeWrapper= require('../mime_wrapper')
hasAnExtension = require('../utilities').hasAnExtension

extensions= ['.txt']

# if adding .txt to the end of the path finds a file, serve the contents of that file
module.exports= implicitTextFileAction= (req,res,next) ->
  try
    fullpath = req.malifi.path.full
    hasAnExtension fullpath, extensions, (found)=>
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
