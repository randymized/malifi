extensions= ['js','coffee']

# invoke the module at the given path if it is present
module.exports= ()->
  justAModuleAction= (req,res,next) ->
    try
      files = req.malifi.files
      for ext in extensions
        if files[ext]
          module = require(files[ext])
          return module(req,res,next)
      next()
    catch e
      next(e)