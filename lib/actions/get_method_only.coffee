# ignore non-GET requests
module.exports= getOnlyAction= (req,res,next) ->
  try
    malifi = req.malifi
    if malifi.meta._getOnly? && 'GET' != req.method && 'HEAD' != req.method
      malifi.next_layer()
    else
      next()
  catch e
    next(e)
