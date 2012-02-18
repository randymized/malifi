# ignore non-GET requests
module.exports= getOnlyAction= (pass) ->
  if @meta.getOnly? && 'GET' != @req.method && 'HEAD' != @req.method
    @next()
  else
    pass()
