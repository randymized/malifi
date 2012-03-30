_ = require('underscore')._
select_actions_by_extension= require('./select_actions_by_extension')

exports = module.exports = select_actions= (req,res,next)->
  if handler = req.malifi.meta._actions
    handler(req,res,next)
  else
    next()