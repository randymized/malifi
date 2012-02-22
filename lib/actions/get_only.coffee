# ignore non-GET requests
module.exports= getOnlyAction= (pass) ->
  try
    if @meta._getOnly? && 'GET' != @req.method && 'HEAD' != @req.method
      @next()
    else
      pass()
  catch e
    @next(e)
