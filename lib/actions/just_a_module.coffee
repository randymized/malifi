hasAnExtension = require('../utilities').hasAnExtension

extensions= ['.js','.coffee']

# invoke the module at the given path if it is present
module.exports= justAModuleAction= (req,res,next) ->
  try
    fullpath = req.malifi.path.full
    hasAnExtension fullpath, extensions, (found)=>
      if found
        require(fullpath)(req,res,next)
      else
        next()
  catch e
    next(e)
