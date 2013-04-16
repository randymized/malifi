# Given an array of actions, the actions will be called serially.
# The first action is called.  If it calls the 'next' function that is passed to it
# the next action in the series is called.  This continues until either one of the
# actions does not call 'next' or until the end of the list is reached.
_ = require('underscore')._
actionOrMetaString= require('../actionOrMetaString')

exports = module.exports = action_series= (silo)->
  action_series_handler= (req,res,next)->
    return next() unless silo
    if _.isFunction(silo)
      silo= [silo]
    i= 0
    nextActionHandler= (err)=>
      return next(err) if err
      try
        actor= silo[i++]
        if (actor)
          actionOrMetaString(actor)(req,res,nextActionHandler)
        else
          next()
      catch e
        next(e)
    nextActionHandler()