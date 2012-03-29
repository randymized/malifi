module.exports= (req,res,next)->
  q= req._.url.parsed.query
  debugger
  req._.meta._reroute(
    '/'+(q.what ? 'nothing'),
    'example.com'
  )(req,res,next)