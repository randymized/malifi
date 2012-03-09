module.exports= (req,res,next)->
  req._.meta._reroute('/_hidden.txt')(req,res,next)