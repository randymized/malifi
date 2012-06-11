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
actionOrMetaString= require('../actionOrMetaString')

exports = module.exports = select_actions_by_extension= (extLookup)->
  select_actions_by_extension_handler=
    if extLookup?
      (req,res,next)->
        malifi= req.malifi
        extLookup= malifi.meta[extLookup] if _.isString(extLookup)
        pathobj= malifi.path
        action= if pathobj.extension == ['/']
          extLookup['/']
        else
          extLookup[pathobj.extension] ? extLookup['*']

        if action?
          actionOrMetaString(action)(req,res,next)
        else
          next()
    else
      (req,res,next)->
        next()
