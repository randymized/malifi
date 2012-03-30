malifiMod= require('../../../..') # require('malifi')
module.exports= (prev)->
  actions_:
    prev.actions_.extend (methodmap)->
      GET: methodmap.GET.extend (extmap)->
        '': malifiMod.action_handlers.serve_directory_listings('serve_directory_listings_options_')