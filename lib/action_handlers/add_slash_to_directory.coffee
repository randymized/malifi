# If the URL does not end with a slash, redirect so that it does end with a slash
endswith= /\/$/
module.exports= addSlashToDirectory= (req,res,next) ->
  try
    url = req._.url
    unless endswith.test(url.decoded_path)
      res.statusCode = 301;
      newpath = url.raw+'/'
      res.setHeader('Location', newpath);
      res.end('Redirecting to ' + newpath);
    else
      next()
  catch e
    next(e)
