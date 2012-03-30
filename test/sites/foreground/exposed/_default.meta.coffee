module.exports= (prev)->
  actions_:
    prev.actions_.extend (methodmap)->
      GET: methodmap.GET.extend (extmap)->
        '': require('../../../../lib/action_handlers/serve_directory_listings')('serve_directory_listings_options_')