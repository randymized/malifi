# ignore non-GET requests
module.exports= getOnlyAction= (pass) ->
  if @meta._getOnly? && 'GET' != @req.method && 'HEAD' != @req.method
    @next()
  else
    pass()
