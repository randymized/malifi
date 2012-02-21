module.exports= ()->
  # unable to respond
  @req.socket.destroy() if (@res.headerSent)

  @res.statusCode=500
  @res.setHeader('Content-Type','text/plain')
  if ('HEAD' == @req.method)
    @res.end()
  else
    @res.end((_err? && _err.msg) || 'Internal server error')
