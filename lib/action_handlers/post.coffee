# default handling of POST requests
malifiMod= require('../..')
hasAnExtension = malifiMod.has_an_extension
extensions= ['post.js','post.coffee']

module.exports= ()->
  postAction= (req,res,next) ->
    try
      malifi= req.malifi
      files = malifi.files
      for ext in extensions
        if files[ext]
          if malifi.meta.post_middleware_
            ranMiddleware= true
            return malifi.meta.post_middleware_ req, res, (err)->
              return next(err) if err
              return require(files[ext])(req,res,next)
          return require(files[ext])(req,res,next)
      next()
    catch e
      next(e)
