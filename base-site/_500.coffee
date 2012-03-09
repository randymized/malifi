# _500 handlers allow custom display in the case of unhandled errors.
# The simplest case is a reply with a status code of 500 (hence the name of
# the handler) and a message like "Internal Server Error".  But the handler
# could potentially be styled for a friendlier interface that matches the
# site's look and feel.

env = process.env.NODE_ENV || 'development';

module.exports= (req,res,next)->
  err= req.err || new Error('unknown error')

  msg= if 'production' == env
    'Internal Server Error'
  else
    err.stack || err.toString()

  # output to stderr in a non-test env
  if 'test' != env
    console.error(err.stack || err.toString())

  # unable to respond
  if res.headerSent
    return req.socket.destroy()

  res.statusCode = 500;
  res.setHeader('Content-Type', 'text/plain');
  return res.end() if 'HEAD' == req.method
  res.end(msg);
