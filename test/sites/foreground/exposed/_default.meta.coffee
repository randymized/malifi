module.exports= (prev)->
  _actions:
    'GET':
      '/': [
          require('../../../../lib/action_handlers/serve_directory_listings')
      ]
      '*': prev._actions.GET['*']