connect = require('connect')
utils = connect.utils

exports = module.exports = action= (actions)->
  i= -1
  pass= ()=>
    i+= 1
    if (actions.length > i)
      actions[i].call(this,pass)
    else
      @next()
  pass()

exports.defaultActions= [
    require('./actions/get_only')
  , require('./actions/text_file')
  , require('./actions/just_a_module')
]