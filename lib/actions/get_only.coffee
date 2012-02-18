# ignore non-GET requests
module.exports= getOnlyAction= (pass,req,res,next,malifi,meta) ->
  if req.malifi.meta.getOnly? && 'GET' != req.method && 'HEAD' != req.method
    next()
  else
    pass()
