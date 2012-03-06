module.exports= (req,res,next)->
  res.statusCode=404
  res.setHeader('Content-Type','text/plain')
  if ('HEAD' == req.method)
    res.end()
  else
    res.end('Cannot '+req.method+' '+req.url);
