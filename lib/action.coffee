connect = require('connect')
utils = connect.utils

exports = module.exports = action= ()->
  actions= @meta._actions
  actionList= actions[@pathinfo.path.extension] ? actions['*']
  @next() unless actionList
  i= -1
  pass= ()=>
    i+= 1
    if (actionList.length > i)
      actionList[i].call(this,pass)
    else
      @next()
  pass()