module.exports= (req,res,next)->
  req._.meta.reroute_('/hidden_.txt')(req,res,next)