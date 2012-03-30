_ = require('underscore')._

exports = module.exports = action_series= (silo)->
  action_series_handler= (req,res,next)->
    return next() unless silo
    if _.isFunction(silo)
      silo= [silo]
    i= 0
    nextActionHandler= (err)=>
      next(err) if err
      try
        actor= silo[i++]
        if (actor)
          actor(req,res,nextActionHandler)
        else
          next()
      catch e
        next(e)
    nextActionHandler()