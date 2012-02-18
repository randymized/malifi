connect = require('connect')
utils = connect.utils

exports = module.exports = action= (actions)->
  i= -1
  actionobj= this
  pass= ()->
    i+= 1
    if (actions.length > i)
      actions[i].call(actionobj,pass)
    else
      actionobj.next()
  pass()

exports.defaultActions= [
    require('./actions/get_only')
  , require('./actions/text_file')
  , require('./actions/just_a_module')
]