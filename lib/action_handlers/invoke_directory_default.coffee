# look for a directory's _index resource and if present, serve it
path= require('path')
module.exports= (indexResourceName)->
  invoke_directory_default= (req,res,next) ->
    try
      malifi = req.malifi
      if malifi.files['/']
        malifi.meta.reroute_(path.join(malifi.path.relative,malifi.meta[indexResourceName]))(req,res,next)
      else
        next()
    catch e
      next(e)