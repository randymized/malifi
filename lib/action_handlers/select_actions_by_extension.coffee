# Select an action based upon the URL's extension.
# The argument to the initializing function should be an extension lookup object:
# an object that is indexed by extension.  Extension, in this case includes the
# following special values:
#  '': The request did not include any extension
#  '/': The last character of the request was a slash (directory request)
#  '*': Wildcard for any request that includes an extension but where the
#       extension does not match any of the attributes of the extension lookup
#       argument.
_= require('underscore')
exports = module.exports = select_actions_by_extension= (extLookup)->
  handler= select_actions_by_extension_handler=
    if extLookup?
      (req,res,next)->
        pathobj= req.malifi.path
        action= if pathobj.extension == ['/']
          extLookup['/']
        else
          extLookup[pathobj.extension] ? extLookup['*']

        if action?
          action(req,res,next)
        else
          next()
    else
      (req,res,next)->
        next()

  # Attachments to the handler to allow identification and creating copies
  handler.__defineGetter__ 'args', ()->
    _.clone(extLookup)
  handler.filename= __filename
  handler.extend= (editor)->
    old_map = _.clone(extLookup)
    select_actions_by_extension(_.extend(old_map, editor(old_map)))

  handler
