connect= require('connect')
_= require('underscore')
malifiMod= require(require('./_root'))

module.exports= (prev)->
  test_string: 'common'
  get_action_map_: _.extend(
    prev.get_action_map_,
    test: malifiMod.action_handlers.serve_if_module()
  )
  allowed_url_extensions_: prev.allowed_url_extensions_.concat('test')
  post_middleware_: connect.urlencoded()
