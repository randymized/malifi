connect = require('connect')
utils = connect.utils

exports = module.exports = action= (actions,req,res,next)->
  actionobj=
    req: req
    res: res
    next: next
    malifi: req.malifi
    meta: req.malifi.meta
  do ->
    i= -1
    pass= ()->
      i+= 1
      if (actions.length > i)
        actions[i].call(actionobj,pass)
      else
        next()
    pass()

exports.defaultActions= [
    require('./actions/get_only')
  , require('./actions/text_file')
  , require('./actions/just_a_module')
]