connect = require('connect')
utils = connect.utils

exports = module.exports = action= ()->
  actions= @meta._actions
  i= -1
  pass= ()=>
    i+= 1
    if (actions.length > i)
      actions[i].call(this,pass)
    else
      @next()
  pass()