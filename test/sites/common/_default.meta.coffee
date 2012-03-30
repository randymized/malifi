module.exports= (prev)->
  test_string: 'common'
  actions_:
    prev.actions_.extend (methodmap)->
      GET: methodmap.GET.extend (extmap)->
          test: require('../../../lib/action_handlers/serve_if_module')()
  allowed_url_extensions_: prev.allowed_url_extensions_.concat('test')
