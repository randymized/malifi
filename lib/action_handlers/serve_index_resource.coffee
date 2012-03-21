# Serve the directory's _index module
path = require('path')

module.exports= (metaname)->
  serveDirectoryModule= (req,res,next) ->
    try
      malifi = req._
      meta = malifi.meta
      if (indexResourceName = meta[metaname])
        indexurl= path.join(malifi.url.raw,indexResourceName)
        meta._reroute(indexurl)(req,res,next)
    catch e
      next(e)
