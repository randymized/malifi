_ = require('underscore')._
action_series = require('./action_series')

exports = module.exports = select_actions= (req,res,next)->

  traverseActionList= (silo)->
    action_series(silo)(req,res,next)

  malifi = req.malifi
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
