# default handling of POST requests
hasAnExtension = require('../utilities').hasAnExtension
extensions= ['.js','.coffee']

module.exports= postAction= (req,res,next) ->
  try
    debugger
    modname = req.malifi.path.full+'.post'
    hasAnExtension modname, extensions, (found)=>
      if found
        try
          require(found)(req,res,next)
        catch e
            next(e)
      else
        next()
  catch e
    next(e)
