# Select an action based upon the HTTP method.
# The argument to the initializing function should map from an HTTP method,
# such as GET or POST to an action handler that is to be invoked when a request
# of that method is received.
# HEAD requests are routed to the GET handler unless one is specifically provided.
_= require('underscore')
actionOrMetaString= require('../actionOrMetaString')

exports = module.exports = select_actions_by_http_method= (map)->
  select_actions_by_http_method_handler=
    if map
      (req,res,next)->
        map= req.malifi.meta[map] if _.isString(map)
        method= req.method
        if (action= map[method])
          actionOrMetaString(action)(req,res,next)
        else if ('HEAD' == action && (action= map['GET']))
          actionOrMetaString(action)(req,res,next)
        else
          next()
    else
      (req,res,next) ->
        next()
