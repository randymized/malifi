_= require('underscore')

exports= module.exports= actionOrMetaString= (subaction)->
  unless subaction
    return (req,res,next)->
      next()
  if _.isString(subaction)
    (req,res,next)->
      req.malifi.meta[subaction](req,res,next)
  else
    subaction
