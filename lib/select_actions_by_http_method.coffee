# Select an action based upon the HTTP method.
# The argument to the initializing function should map from an HTTP method,
# such as GET or POST to an action handler that is to be invoked when a request
# of that method is received.
# HEAD requests are routed to the GET handler unless one is specifically provided.
_= require('underscore')
exports = module.exports = select_actions_by_http_method= (map)->
  handler= select_actions_by_http_method_handler=
    if map
      m= _.clone(map)
      m['HEAD']= m['GET'] unless m['HEAD']?
      (req,res,next)->
        if (action= m[req.method])
          action(req,res,next)
        else
          next()
    else
      (req,res,next) ->
        next()

  # Attachments to the handler to allow identification and creating copies
  handler.__defineGetter__ 'args', ()->
    _.clone(map)
  handler.filename= __filename
  handler.extend= (editor)->
    old_map = _.clone(map)
    select_actions_by_http_method(_.extend(old_map, editor(old_map)))
  handler
