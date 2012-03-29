# look for a directory's _index resource and if present, serve it
path= require('path')
select_actions= require('../select_actions')
module.exports= (indexResourceName)->
  invoke_directory_default= (req,res,next) ->
    try
      malifi = req.malifi
      if malifi.files['/']
        malifi.meta._reroute(path.join(malifi.path.relative,malifi.meta[indexResourceName]))(req,res,next)
      else
        next()
    catch e
      next(e)