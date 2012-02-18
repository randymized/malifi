# ignore non-GET requests
module.exports= getOnlyAction= () ->
  when: (req,malifi,meta)->
    req.malifi.meta.getOnly? && 'GET' != req.method && 'HEAD' != req.method
  run: (req,res,next) ->
    next()
