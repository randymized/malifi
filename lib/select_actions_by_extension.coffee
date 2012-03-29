# Select an action based upon the URL's extension.
# The argument to the initializing function should be an extension lookup object:
# an object that is indexed by extension.  Extension, in this case includes the
# following special values:
#  '': The request did not include any extension
#  '/': The last character of the request was a slash (directory request)
#  '*': Wildcard for any request that includes an extension but where the
#       extension does not match any of the attributes of the extension lookup
#       argument.
exports = module.exports = select_actions_by_extension= (extLookup)->
  select_actions_by_extension_handler= (req,res,next)->
    return next() unless extLookup?

    pathobj= req.malifi.path
    action= if pathobj.extension == ['/']
      extLookup['/']
    else
      extLookup[pathobj.extension] ? extLookup['*']

    if action?
      action(req,res,next)
    else
      next()
