module.exports= (req,res,next)->
  q= req._.url.parsed.query
  req._.meta.reroute_(
    '/a.txt',
    'unk.localhost'
  )(req,res,next)