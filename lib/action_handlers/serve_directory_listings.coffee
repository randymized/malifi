#If the URL names a directory, serve up a listing of that directory.
fs = require('fs')
directory = require('connect').middleware.directory
module.exports= (metaOptionsName)->
  serveDirectoryListings= (req,res,next) ->
    try
      meta= req.malifi.meta
      fullpath = req.malifi.path.full
      options= meta[metaOptionsName] ? {}
      fs.stat fullpath, (err,stats)->
        if !err && stats.isDirectory()
          try
            options.filter ?= (file)->
              !meta._forbiddenURLChars?.test('/'+file)
            directory(req.malifi.path.site_root,options)(req,res,next)
          catch e
            next(e)
        else
          next()
    catch e
      next(e)
