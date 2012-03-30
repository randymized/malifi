malifiMod= require('..')
main_action = malifiMod.action_handlers.main_action
action_series = malifiMod.action_handlers.action_series
select_actions_by_extension = malifiMod.action_handlers.select_actions_by_extension
select_actions_by_http_method = malifiMod.action_handlers.select_actions_by_http_method
allowed_extensions= ['txt','pdf','html','htm','gif','jpg','jpeg','ico','tif','png','tiff','bmp']

module.exports=
  # An object named 'malifi' will be added to req.  That object contains references
  # to the current metadata, a method to look up other metadata, the site stack
  # and decoded path, url and host strings.  If malifi_alias_ is defined in the
  # metadata, a second reference to the same object will be added to req using
  # that name.  Assuming the default of '_', the metadata can be accessed either
  # as req.malifi.meta or req._.meta
  malifi_alias_: '_'

  # The action to be performed when a request is received and after the metadata
  # has been obtained and the req.malifi object created.
  # The default action established here, invokes main_action to perform
  # some sanity checks and to find files that may serve the request.
  # It then passes the request to select_actions_by_http_method, which selects
  # further action based upon HTTP method (GET,POST,etc).  A GET request
  # passes through another selection (select_actions_by_extension) based upon
  # whether the request includes an extension or ends with a slash.  The
  # action_series action is also used in some cases to step the request
  # through a series of handlers until one is found that handles the request.
  # Although the actions_ attribute is simply an action handler, that action
  # handler as demonstrated here, may delegate to other action handlers,
  # creating a complex pattern of possible responses based upon the request
  # and the files available to serve that request.
  actions_: main_action( select_actions_by_http_method {
    'GET': select_actions_by_extension {
      '/': action_series [
          malifiMod.action_handlers.invoke_directory_default('indexResourceName_')
        , malifiMod.action_handlers.directory_index('directory_index_module_')
        ]
      '': action_series [
          malifiMod.action_handlers.add_slash_to_directory()
        , malifiMod.action_handlers.serve_if_module()
        , malifiMod.action_handlers.implied_static_file('implied_static_extensions_')
        ]
      '*': action_series [
          malifiMod.action_handlers.serve_if_module()
        , malifiMod.action_handlers.explicit_static_file('allowed_static_extensions_')
        ]
      }
    'POST': malifiMod.action_handlers.post()
  })

  # The module that will serve reroute requests.
  # Reroute is an internal redirect.  The request will be served as if it were
  # for the new URL rather than the original one.  Rerouted requests may access
  # pages that are otherwise hidden (see forbiddenURLChars_).
  # With rerouting, the entire page (or response) is served from the new
  # destination.  The partial module should be used instead if you want to
  # include content from one page inside another.
  reroute_: malifiMod.reroute

  # A "partial" allows the content from one page to be included within another.
  # A partial page may be served by a page that is otherwise hidden (see
  # forbiddenURLChars_).
  # The data output from the partial will be accumulated and made available to
  # the callback method provided.  The output data will be in the form of a
  # buffer and may need to be converted to a string via its toString() method.
  partial_: malifiMod.partial

  # If custom_404_ is true, unserviced requests are not passed on to the next
  # level of middleware, but instead result in rerouting to a custom _404 page.
  # A default _404 page will be shown if one has not been defined for the site.
  custom_404_: false

  # If custom_500_ is true, next(err) will unserviced requests are not passed on to the next
  # level of middleware, but instead result in rerouting to a custom _500 page.
  # A default _500 page will be shown if one has not been defined for the site.
  custom_500_: false

  # Valid URLs may include the following extensions.
  # Any other extensions at the end of a URL will be disallowed.
  allowed_url_extensions_: allowed_extensions

  # Static files may be served if they have the following extensions and
  # either the URL includes the extension or the URL has no extension but
  # otherwise matches the file.
  # The lib/action_handlers/explicit_static_file handler provides a
  # reference implementation that serves explicitly specified files that are
  # on this list.
  allowed_static_extensions_: allowed_extensions

  # A URL that does not include an extension may be matched with a static
  # resource that has an extension included in this array.  For example,
  # a request for "/a" may serve "/a.txt" if that file is present and its
  # extension is included here.
  # The lib/action_handlers/implied_static_file handler provides a
  # reference implementation that serves explicitly specified files that are
  # on this list.
  implied_static_extensions_: ['html','txt','htm']

  # If defined and not null, any URLs matching this regular expression will be
  # rejected as forbidden.  The default rejects URLs where any element starts
  # with a dot or with an underline or which end with an underline.  The
  # underline rejection is a Malifi convention in which file or directory
  # names starting with an underline are special files having some meaning to
  # malifi but not intended to be served and where names ending with an
  # underline are only served if the subject of an internal redirect or serve
  # as partials.
  forbiddenURLChars_: /(\/[._])|(_\/)|_$/

  # The module named here can be invoked to produce an index of a directory named
  # in the URL.  Default processing of a url that ends with a slash is to first
  # look for an `indexResourceName_` module within that directory, and if not
  # present, then invoke this module, if specified.  If this attribute is false
  # no directory index will be produced.
  directory_index_module_: false  # malifi.serve_directory_listings()

  # In many servers, if a URL is of a directory and a script of the right name,
  # such as index.whatever, exists, that script will be run rather than producing
  # a listing of the files in that directory.  Here is where you configure the
  # base name of that script.  This default means that a resource like _index.js,
  # _index.coffee or _index.txt would be served.
  indexResourceName_: '_index'

  # Specify a module that will handle any unhandled exceptions.  Best practice
  # is to exit the process as a result of an unhandled exception, but the handler
  # may log some clues to help identify the problem.  It might also notify
  # someone about the problem.
  # The module should export a 'log' method.  The log method will be bound to
  # the action object and will thus have access to the same member variables
  # as an action handler.  The log method should also register a method
  # to catch unhandled exceptions if the method has not already been registered.
  unhandled_handler_:
    malifiMod.unhandled_exception_handler

  # Options for the _serve_directory_listings action.  These are the options
  # of Connect's directory middleware.
  # If not otherwise specified, a filter that hides any files matching
  # forbiddenURLChars_ will be applied.  This can be overridden by providing
  # an explicit filter.
  serve_directory_listings_options_: {}

  test_string: 'base'
