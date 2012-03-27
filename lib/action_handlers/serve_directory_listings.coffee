#If the URL names a directory, serve up a listing of that directory.
fs = require('fs')
directory = require('connect').middleware.directory
module.exports= (metaOptionsName)->
  serveDirectoryListings= (req,res,next) ->
    try
      malifi = req.malifi
      dirname = malifi.files['/']
      if dirname
        meta= malifi.meta
        options= meta[metaOptionsName] ? {}
        options.filter ?= (file)->
          !meta._forbiddenURLChars?.test('/'+file)
        req.url= '/'
        directory(dirname,options)(req,res,next)
      else
        next()
    catch e
      next(e)
