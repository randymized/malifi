action_series= require('../lib/action_series')

allowed_extensions= ['txt','pdf','html','htm','gif','jpg','jpeg','ico','tif','png','tiff','bmp']
module.exports=
  # An object named 'malifi' will be added to req.  That object contains references
  # to the current metadata, a method to look up other metadata, the site stack
  # and decoded path, url and host strings.  If _malifi_alias is defined in the
  # metadata, a second reference to the same object will be added to req using
  # that name.  Assuming the default of '_', the metadata can be accessed either
  # as req.malifi.meta or req._.meta
  _malifi_alias: '_'

  # The module that is to be invoked whenever a request is received, after
  # looking up the metadata and building the req.malifi object.  The default
  # action module selects and iterates through sites and action silos.
  _main_action: require('../lib/main_action')()

  # The module that will serve reroute requests.
  # Reroute is an internal redirect.  The request will be served as if it were
  # for the new URL rather than the original one.  Rerouted requests may access
  # pages that are otherwise hidden (see _forbiddenURLChars).
  # With rerouting, the entire page (or response) is served from the new
  # destination.  The partial module should be used instead if you want to
  # include content from one page inside another.
  _reroute: require('../lib/reroute')

  # A "partial" allows the content from one page to be included within another.
  # A partial page may be served by a page that is otherwise hidden (see
  # _forbiddenURLChars).
  # The data output from the partial will be accumulated and made available to
  # the callback method provided.  The output data will be in the form of a
  # buffer and may need to be converted to a string via its toString() method.
  _partial: require('../lib/partial')

  # If _custom_404 is true, unserviced requests are not passed on to the next
  # level of middleware, but instead result in rerouting to a custom _404 page.
  # A default _404 page will be shown if one has not been defined for the site.
  _custom_404: false

  # If _custom_500 is true, next(err) will unserviced requests are not passed on to the next
  # level of middleware, but instead result in rerouting to a custom _500 page.
  # A default _500 page will be shown if one has not been defined for the site.
  _custom_500: false

  # Valid URLs may include the following extensions.
  # Any other extensions at the end of a URL will be disallowed.
  _allowed_url_extensions: allowed_extensions

  # Static files may be served if they have the following extensions and
  # either the URL includes the extension or the URL has no extension but
  # otherwise matches the file.
  # The lib/action_handlers/explicit_static_file handler provides a
  # reference implementation that serves explicitly specified files that are
  # on this list.
  _allowed_static_extensions: allowed_extensions

  # A URL that does not include an extension may be matched with a static
  # resource that has an extension included in this array.  For example,
  # a request for "/a" may serve "/a.txt" if that file is present and its
  # extension is included here.
  # The lib/action_handlers/implied_static_file handler provides a
  # reference implementation that serves explicitly specified files that are
  # on this list.
  _implied_static_extensions: ['html','txt','htm']

  # If defined and not null, any URLs matching this regular expression will be
  # rejected as forbidden.  The default rejects URLs where any element starts
  # with a dot or with an underline or which end with an underline.  The
  # underline rejection is a Malifi convention in which file or directory
  # names starting with an underline are special files having some meaning to
  # malifi but not intended to be served and where names ending with an
  # underline are only served if the subject of an internal redirect or serve
  # as partials.
  _forbiddenURLChars: /(\/[._])|(_\/)|_$/

  # The default set of actions to be performed on an incoming request.
  # First the request method: GET, POST, PUT, DELETE, etc is selected.
  # Then the URL's extension.  If there is no extension, the key will be
  # a blank string.  A '*' key will apply to any extensions without a
  # more specific match.  A '/' key is a special case: it applies to
  # cases where the URL matches a directory.  Directories will only be
  # matched to a URL if a '/' key exists.
  # Finally the tree of objects will lead to an array of actions.
  # The actions are invoked in order.  Each may either handle the
  # request by invoking res.end or next to pass on the request or
  # req.malifi.next_middleware_layer to pass the request on to the next connect layer.
  # Each request will thus move down the list until it finds a suitable handler.
  # A typical ordering would have handlers for differnt types of templates
  # first followed by a handler for just a .js or .coffee module.  If
  # template is discovered, its handler will invoke any .js or .coffee
  # module first, providing the coupling expected by the template.
  _actions:
    'GET':
      '/': action_series [
          require('../lib/action_handlers/invoke_directory_default')('_indexResourceName')
        , require('../lib/action_handlers/directory_index')('_directory_index_module')
        ]
      '': action_series [
          require('../lib/action_handlers/add_slash_to_directory')()
        , require('../lib/action_handlers/serve_if_module')()
        , require('../lib/action_handlers/implied_static_file')('_implied_static_extensions')
        ]
      '*': action_series [
          require('../lib/action_handlers/serve_if_module')()
        , require('../lib/action_handlers/explicit_static_file')('_allowed_static_extensions')
      ]
    'POST': require('../lib/action_handlers/post')()

  # The module named here can be invoked to produce an index of a directory named
  # in the URL.  Default processing of a url that ends with a slash is to first
  # look for an `_indexResourceName` module within that directory, and if not
  # present, then invoke this module, if specified.  If this attribute is false
  # no directory index will be produced.
  _directory_index_module: false  # require('../lib/serve_directory_listings')()

  # In many servers, if a URL is of a directory and a script of the right name,
  # such as index.whatever, exists, that script will be run rather than producing
  # a listing of the files in that directory.  Here is where you configure the
  # base name of that script.  This default means that a resource like _index.js,
  # _index.coffee or _index.txt would be served.
  _indexResourceName: '_index'

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

  # Options for the _serve_directory_listings action.  These are the options
  # of Connect's directory middleware.
  # If not otherwise specified, a filter that hides any files matching
  # _forbiddenURLChars will be applied.  This can be overridden by providing
  # an explicit filter.
  _serve_directory_listings_options: {}

  test_string: 'base'
