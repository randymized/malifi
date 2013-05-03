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

  # Hook every request received from Connect before it is handled by Malifi.
  # This is a special attribute that is only effective if set in the options object,
  # the optional second argument to the malifi function that is passed to the connect
  # app.use method.  It is ignored if set anywhere else.
  #
  # If set in the options argument, this attribute's value should be a function that
  # receives one argument.  This function should return a function that will be called
  # immediately when Malifi receives a request from Connect. This hook function ultimately
  # should either call the function that is received as an argument or the `next`
  # function received as an argument.
  hook_main_connect_handler_: null

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
  actions_: main_action('http_action_')
  http_action_: select_actions_by_http_method('http_action_map_')
  http_action_map_:
    'GET': 'get_action_'
    'POST': 'post_action_'
  get_action_: select_actions_by_extension('get_action_map_')
  get_action_map_:
    '/': 'get_directory_action_'
    '':  'get_named_resource_action_'
    '*': 'get_extensioned_resource_action_'
  get_directory_action_: action_series [
    malifiMod.action_handlers.invoke_directory_default('indexResourceName_')
    malifiMod.action_handlers.directory_index('directory_index_module_')
  ]
  get_named_resource_action_: action_series [
    malifiMod.action_handlers.add_slash_to_directory()
    malifiMod.action_handlers.serve_if_module()
    malifiMod.action_handlers.implied_static_file('implied_static_extensions_')
    malifiMod.action_handlers.serve_bare_templates()
  ]
  get_extensioned_resource_action_: action_series [
    malifiMod.action_handlers.explicit_static_file('allowed_static_extensions_')
    malifiMod.action_handlers.serve_if_module()
  ]
  post_action_: malifiMod.action_handlers.post()

  # A handler that will receive all requests and which may preempt Malifi's native
  # routing.  Most commonly, this router would handle URLs that include variable
  # elements, processing the URL against a set of regular expressions or similar
  # patterns to see if the URL is recognized, and if so, storing the variables in
  # the request before rewriting the URL to a resource that will handle the request.
  # If the router rewrites the URL to a hidden resource, it must set req.internal
  # to a true value.
  # The router may also serve the resource directly.
  preempting_router_: malifiMod.action_handlers.dummy_router('')

  # This will be assigned to malifi.render.  It should be a function that renders
  # the current page's template, typically by selecting and delegating to a
  # specific template engine's rendering function. In addion to the usual req, res
  # and next arguments, the function will be passed a mime type and a context
  # object.
  # Given the mime type requested, the renderer is responsible for selecting the
  # template from the members of malifi.files and may select template engine based
  # upon file extension or other criteria.
  renderer_: malifiMod.renderer

  # Specify a function that will return the default template rendering context.
  # In the default renderer, the default context will be used if a null context is
  # provided, such as in the case of a bare template (one without an accompanying
  # module).  A typical function might do things like populate the page title from
  # metadata or URL or create breadcrumb data from the resource's path.
  default_context_fn_: (req)->
    return {}

  # Maps extensions of template files to a rendering function according to desired
  # mime type.  The default renderer expects an object that is indexed by mime type.
  # Each mime type references an array of arrays that provides a prioritized list of
  # extensions and the engine-specific renderer to be used.
  # Like any other metadata, this map can vary for different parts of a site,
  # allowing flexibility in template engine selection.
  template_map_:
    'text/html': [
      ['html', malifiMod.underscore_renderer]
    ]

  # Of the MIME types in template_map_, which should be considered the default?
  template_map_default_MIME_type_: 'text/html'

  # Mime type abreviations.  Allows one to request the html template by passing 'html'
  # to req.malifi.render instead of 'text/html'.
  mime_type_abbreviations_:
    html: 'text/html'
    css: 'text/css'

  # If true, compiled templates will be cached.
  cache_templates_: process.env.NODE_ENV == 'production'

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
  # The module should export a 'log' method.  It will be called whenever a request
  # is received with the request as an argument.  It may save various pieces of data
  # from the request that may aid diagnosis of the problem.  The log method should also
  # register a method to catch unhandled exceptions if the method has not already been
  # registered.
  unhandled_handler_:
    malifiMod.unhandled_exception_handler

  # Options for the _serve_directory_listings action.  These are the options
  # of Connect's directory middleware.
  # If not otherwise specified, a filter that hides any files matching
  # forbiddenURLChars_ will be applied.  This can be overridden by providing
  # an explicit filter.
  serve_directory_listings_options_: {}

  # If build_lineage_ is true, an array named lineage_ will be added to metadata
  # that details the path all metadata inherited by the current metadata.  This is
  # intended for testing and thus not enabled by default, although it may prove to have
  # practical uses.
  #
  # Because the default is false, the lineage will never include this file.  If the
  # options passed to the malifi constructor includes 'build_lineage_':true, the
  # first object in the array will be the string '(options)', the last object will
  # be the most specific metadata's module name with the name of other metadata modules
  # contributing to the metadata listed in the order in which they contributed.
  build_lineage_: false

  # path_ will be filled in with the site-relative path to the file containing the
  # most specific metadata for the requested resource.  If there is no .meta file
  # for the requested resource, nor is there a meta attribute in any module serving
  # that resource, the path will be trimmed back, one directory at a time until
  # metadata is found.  This _path attribute reflects where metadata was actually found.
  path_: false

  # Set the Cache-Control max-age value in milliseconds.  This assumes that the action handler that actually delivers
  # the file or other resource refers to this attribute.  The static_streamer action handler, which is the default
  # action that serves static files, does use this attribute.  The default is zero, but can be set to a larger
  # value for applicable directories or for individual resources.  If set to Infinity, Static_streamer will set the
  # Cache-Control max-age to one year.
  max_age_: 0
