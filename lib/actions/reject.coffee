# This will reject any request that is directed to it.  Unless a later layer
# serves the request, this will result in a 404 error
module.exports= getOnlyAction= (req,res,next) ->
  req.malifi.next_layer()
