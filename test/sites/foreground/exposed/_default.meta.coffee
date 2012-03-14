module.exports= (prev)->
  _actions:
    'GET':
      '/': [
          require('../../../../lib/actions/serve_directory_listings')
      ]
      '*': prev._actions.GET['*']