_ = require('underscore')._
select_actions_by_extension= require('./select_actions_by_extension')

exports = module.exports = select_actions= (req,res,next)->
  malifi = req.malifi
  extLookup= malifi.meta._actions[if req.method is 'HEAD' then 'GET' else req.method]
  return next() unless extLookup?

  if _.isArray(extLookup) ||_.isFunction(extLookup)
    extLookup(req,res,next)
  else
    select_actions_by_extension(extLookup)(req,res,next)