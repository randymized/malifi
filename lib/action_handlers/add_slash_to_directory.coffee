# If the URL does not end with a slash, redirect so that it does end with a slash
module.exports= ()->
  addSlashToDirectory= (req,res,next) ->
    try
      malifi = req._
      url = malifi.url
      if malifi.files['/'] && '/' != malifi.path.extension
        res.statusCode = 301;
        parsed= url.parsed
        parsed.path+= '/'
        parsed.pathname+= '/'
        newpath = require('url').format(parsed)
        res.setHeader('Location', newpath);
        res.end('Redirecting to ' + newpath);
      else
        next()
    catch e
      next(e)
