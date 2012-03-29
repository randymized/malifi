module.exports= (req,res,next)->
  req._.meta._reroute('/hidden_.txt')(req,res,next)