module.exports= (prev)->
  _actions:
    'GET':
      '': require('../../../../lib/action_handlers/serve_directory_listings')('_serve_directory_listings_options')
      '*': prev._actions.GET['*']