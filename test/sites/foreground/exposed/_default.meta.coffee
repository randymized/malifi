_= require('underscore')
malifiMod= require('../../../..') # require('malifi')
action_series = malifiMod.action_handlers.action_series
module.exports= (prev)->
  get_named_resource_action_: action_series [
    malifiMod.action_handlers.serve_directory_listings('serve_directory_listings_options_')
  , malifiMod.action_handlers.implied_static_file('implied_static_extensions_')
  ]
