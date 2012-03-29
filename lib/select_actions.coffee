_ = require('underscore')._
action_series = require('./action_series')

exports = module.exports = select_actions= (req,res,next)->
  malifi = req.malifi
  extLookup= malifi.meta._actions[if req.method is 'HEAD' then 'GET' else req.method]
  return next() unless extLookup?

  if _.isArray(extLookup) ||_.isFunction(extLookup)
    extLookup(req,res,next)
  else
    pathobj= malifi.path
    if pathobj.extension == ['/']
      extLookup['/'](req,res,next)
    else
      (extLookup[pathobj.extension] ? extLookup['*'])(req,res,next)
