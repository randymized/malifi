_ = require('underscore')._

exports = module.exports = select_actions= (req,res,next)->
  malifi= req.malifi
  malifi.next_middleware_layer= next

  traverseActionList = (silo,nextActionList)=>
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

  extLookup= malifi.meta._actions[if req.method is 'HEAD' then 'GET' else req.method]
  return next() unless extLookup?

  if _.isArray(extLookup) ||_.isFunction(extLookup)
    traverseActionList(extLookup)
  else
    pathobj= malifi.path
    if pathobj.extension == ['/']
      traverseActionList(extLookup['/'])
    else
      traverseActionList(extLookup[pathobj.extension] ? extLookup['*'])
