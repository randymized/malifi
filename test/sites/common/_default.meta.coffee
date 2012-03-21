module.exports= (prev)->
  test_string: 'common'
  _actions: do(prev)->
    prev._actions.GET.test= require('../../../lib/action_handlers/serve_if_module')()
    prev._actions
  _allowed_url_extensions: prev._allowed_url_extensions.concat('test')
