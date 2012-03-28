# default handling of POST requests
hasAnExtension = require('../utilities').hasAnExtension
extensions= ['post.js','post.coffee']

module.exports= ()->
  postAction= (req,res,next) ->
    try
      files = req.malifi.files
      for ext in extensions
        if files[ext]
          return require(files[ext])(req,res,next)
      next()
    catch e
      next(e)
