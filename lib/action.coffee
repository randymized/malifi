connect = require('connect')
utils = connect.utils

exports = module.exports = action= (actions,req,res,next)->
  malifi= req.malifi
  meta= malifi.meta
  i= -1
  pass= ()->
    i+= 1
    if (actions.length > i)
      actions[i](pass,req,res,next,malifi,meta)
    else
      next()
  pass()

exports.defaultActions= [
    require('./actions/get_only')
  , require('./actions/text_file')
  , require('./actions/just_a_module')
]