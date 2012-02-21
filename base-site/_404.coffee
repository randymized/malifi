module.exports= ()->
  @res.statusCode=404
  @res.setHeader('Content-Type','text/plain')
  if ('HEAD' == _req.method)
    @res.end()
  else
    @res.end('Cannot '+_req.method+' '+_req.url);
