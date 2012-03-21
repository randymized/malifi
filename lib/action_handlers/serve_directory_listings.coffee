#If the URL names a directory, serve up a listing of that directory.
fs = require('fs')
directory = require('connect').middleware.directory
module.exports= ()->
  serveDirectoryListings= (req,res,next) ->
    try
      meta= req.malifi.meta
      fullpath = req.malifi.path.full
      fs.stat fullpath, (err,stats)->
        if !err && stats.isDirectory()
          try
            options= _serve_directory_listings_options ? {}
            options.filter ?= (file)->
              !meta._forbiddenURLChars?.test('/'+file)
            directory(req.malifi.path.site_root,options)(req,res,next)
          catch e
            next(e)
        else
          next()
    catch e
      next(e)
