# If the URL does not end with a slash, redirect so that it does end with a slash
module.exports= ()->
  addSlashToDirectory= (req,res,next) ->
    try
      url = req._.url
      unless '/' == req._.path.extension
        res.statusCode = 301;
        newpath = url.raw+'/'
        res.setHeader('Location', newpath);
        res.end('Redirecting to ' + newpath);
      else
        next()
    catch e
      next(e)
