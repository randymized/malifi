module.exports= (prev)->
  test_string: 'common'
  _actions:
    prev._actions.extend (methodmap)->
      GET: methodmap.GET.extend (extmap)->
          test: require('../../../lib/action_handlers/serve_if_module')()
  _allowed_url_extensions: prev._allowed_url_extensions.concat('test')
