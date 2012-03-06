allowed_extensions= ['txt','pdf','html','htm','gif','jpg','jpeg','ico','tif','png','tiff','bmp']
module.exports=
  # If getOnly is true, only GET or HEAD requests will be handled, unless a
  # request-type specific handler is found.
  # For example, if a POST request is received for /foo/bar, the request will
  # be 404ed unless there is a *.post.js, *.post.coffee or other such post-
  # specific handler
  _getOnly: true

  # An object named 'malifi' will be added to req.  That object contains references
  # to the current metadata, a method to look up other metadata, the site stack
  # and decoded path, url and host strings.  If _malifi_alias is defined in the
  # metadata, a second reference to the same object will be added to req using
  # that name.  Since the default is '_', the metadata can be accessed either as
  # req.malifi.meta or req._.meta
  _malifi_alias: '_'

  # Valid URLs may include the following extensions.
  # Any other extensions at the end of a URL will be disallowed.
  _allowed_url_extensions: allowed_extensions

  # Static files may be served if they have the following extensions and
  # either the URL includes the extension or the URL has no extension but
  # otherwise matches the file.
  _allowed_static_extensions: allowed_extensions

  # If defined and not null, any URLs matching this regular expression will be
  # rejected as forbidden.  The default rejects URLs where any element starts
  # with a dot or with an underline or which end with an underline.  The
  # underline rejection is a Malifi convention in which file or directory
  # names starting with an underline are special files having some meaning to
  # malifi but not intended to be served and where names ending with an
  # underline are only served if the subject of an internal redirect or serve
  # as partials.
  _forbiddenURLChars: /(\/[._])|(_\/)|_$/

  # The require(module) function is synchronous and will block if the module
  # needs to be loaded from disk.  Modules will be preloaded when Malifi is
  # started so that they are already cached and thus available without a blocking
  # operation.  _preload_modules may be set to false for a site or directory
  # if memory is tight and there are a large number of modules that are unlikely
  # to be accessed.
  _preload_modules: true

  # The default set of actions to be performed on an incoming request.
  # First the request method: GET, POST, PUT, DELETE, etc is selected.
  # Then the URL's extension.  If there is no extension, the key will be
  # a blank string.  A '*' key will apply to any extensions without a
  # more specific match.  A '/' key is a special case: it applies to
  # cases where the URL matches a directory.  Directories will only be
  # matched to a URL if a '/' key exists.
  # After selecting by method and extension, an additional, optional, layer
  # may provide a dir: and/or file: fork.  The dir fork will be taken if the
  # URL corresponds to a directory.  Without a dir fork, if the URL will not
  # successfully match a directory.
  # Finally the tree of objects will lead to an array of actions.
  # The actions are invoked in order.  Each may either handle the
  # request by invoking res.end or next to pass on the request or
  # req.malifi.next_layer to pass the request on to the next connect layer.
  # Each request will thus move down the list until it finds a suitable handler.
  # A typical ordering would have handlers for differnt types of templates
  # first followed by a handler for just a .js or .coffee module.  If
  # template is discovered, its handler will invoke any .js or .coffee
  # module first, providing the coupling expected by the template.
  _actions:
    'GET':
      '/': [
          #todo define and test a meaningful directory (dir:) action silo
          require('../lib/actions/reject')
        ]
      '': [
          require('../lib/actions/get_only')
        , require('../lib/actions/just_a_module')
        ]
      '*': [
          require('../lib/actions/get_only')
        , require('../lib/actions/just_a_module')
        , require('../lib/actions/static_file')
      ]

  # Specify a module that will handle any unhandled exceptions.  Best practice
  # is to exit the process as a result of an unhandled exception, but the handler
  # may log some clues to help identify the problem.  It might also notify
  # someone about the problem.
  # The module should export a 'log' method.  The log method will be bound to
  # the action object and will thus have access to the same member variables
  # as an action handler.  The log method should also register a method
  # to catch unhandled exceptions if the method has not already been registered.
  _unhandled_handler:
    require('../lib/unhandled_exception_handler')

  test_string: 'base'
