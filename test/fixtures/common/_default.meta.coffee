module.exports= (prev)->
  test_string: 'common'
  _allowed_url_extensions: prev._allowed_url_extensions.concat(['test'])
  _actions: prev._actions.change (newAction)->
    newAction.GET.test=
      [
        require('../../../lib/actions/get_only')
      , require('../../../lib/actions/just_a_module')
      ]
