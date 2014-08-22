malifiMod= require('../..')
http_accept = require('http-accept')
mime = require('mime')
_ = require('underscore')
staticStreamer= malifiMod.static_streamer
hasAnExtension = malifiMod.has_an_extension

# If adding one of the extensions in meta.implied_static_extensions_ to the end
# of the path finds a file, serve the contents of that file
module.exports= (impliedExtensions)->
  implicitFileAction= (req,res,next) ->
    select= ()->
      try
        malifi = req.malifi
        files = malifi.files
        meta= malifi.meta
        mime_map = {}
        mime_list = []
        for ext in _.keys(files)
          file = files[ext]
          file_mime = mime.lookup(file)
          mime_list.push file_mime
          mime_map[file_mime] = {file:file, ext:ext}
        # Note:
        # The order of the file extensions in implied_static_extensions_
        # determines which will be returned from getBestMatch() if
        # the user-agent has no preference.
        best_mime= req.accept.types.getBestMatch(mime_list)
        if mime_map[best_mime]
          files['']= mime_map[best_mime].file
          res.header('TCN', 'choice');
          res.header('Vary', 'negotiate,accept,Accept-Encoding,User-Agent');
          res.header('Content-Location', malifi.path.basename + '.' + mime_map[best_mime].ext);
          return staticStreamer(req,res,next)
        next()
      catch e
        next(e)
    
    if req.accept?.types?
      select()
    else
      # http-accept is not in the middleware stack: insert its results
      http_accept req,res,(err)->
        return next(err) if err
      select()

