env = process.env.NODE_ENV || 'development';

module.exports= (req,res,next)->
  res.statusCode=404
  res.setHeader('Content-Type','text/plain')
  if ('HEAD' == req.method)
    res.end()
  else
    name= if 'production' == env
      req.originalUrl || req.url
    else
      '//'+req.malifi.host.name+req.notfound
    res.end('Cannot '+req.method+' '+name);
