hasAnExtension = require('../utilities').hasAnExtension

extensions= ['js','coffee']

# invoke the module at the given path if it is present
module.exports= ()->
  justAModuleAction= (req,res,next) ->
    try
      pathinfo = req.malifi.path
      prepend= (pathinfo.extension && '/' != pathinfo.extension && pathinfo.extension+'.') || ''
      files = req.malifi.files
      for ext in extensions
        ext= prepend+ext
        if files[ext]
          module = require(files[ext])
          return module(req,res,next)
      next()
    catch e
      next(e)