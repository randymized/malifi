module.exports=
  # If getOnly is true, only GET or HEAD requests will be handled, unless a
  # request-type specific handler is found.
  # For example, if a POST request is received for /foo/bar, the request will
  # be 404ed unless there is a *.post.js, *.post.coffee or other such post-
  # specific handler
  _getOnly: true

  # The default set of actions to be performed on an incoming request.
  # The actions are invoked in order.  Each may either handle the request
  # by invoking @res.end or @next or pass on the request.  Each request
  # will thus move down the list until it finds a suitable handler.
  # A typical ordering would have handlers for differnt types of templates
  # first followed by a handler for just a .js or .coffee module.  If
  # template is discovered, its handler will invoke any .js or .coffee
  # module first, providing the coupling expected by the template.
  _actions:
    '': [
        require('../lib/actions/get_only')
      , require('../lib/actions/just_a_module')
    ]
    '*': [
        require('../lib/actions/get_only')
      , require('../lib/actions/text_file')
    ]

  test_string: 'base'
