module.exports= (req,res,next)->
  q= req._.url.parsed.query
  req._.meta._reroute(
    '/a.txt',
    'common.localhost'
  )(req,res,next)