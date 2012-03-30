module.exports= (prev)->
  _actions:
    prev._actions.extend (methodmap)->
      GET: methodmap.GET.extend (extmap)->
        '': require('../../../../lib/action_handlers/serve_directory_listings')('_serve_directory_listings_options')