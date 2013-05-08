# malifi

MAny LIttle FIles.

A Connect layer where URLs map, by default, directly to the files and resources needed to serve the request.  All files that serve a given request, such as code, template, CSS and supporting javascript are stored together rather than scattered around the filesystem.  Resources that support a GET can be found in the same directory as resources supporting a POST, and by use of a naming convention can exist in a separate set of filesa.  Malifi allows a design centered around many small specialized files and implicit routing over one where logic tends to concentrate in a monolithic controller file and where routing must be explicitly defined.

Malifi natively supports multiple sites and layering of resources so that multiple sites may inherit from a common model or common resources or where skins inherit functionality from an underlying logical layer.

Malifi implements a system of metadata that may be specified for each resource and each directory and for that metadata to inherit from the directories in which the resource resides and for the metadata of each resource in a site to be inherited from underlying sites.  Much of the behavior of Malifi is defined in the metadata and thus different behavior can be specified for different resources, for all the resources in a directory or for an entire site.  Through multiple layers of inheritance, metadata may include components that are very specific to a given servable resource but still ultimately based upon a layer that is common to all implementations of a given version of Malifi.  While a set of metadata attribute names are reserved for Malifi, the metadata system may be used to flexibly specify any data that for any resource is immutable during the server's runtime.

Malifi also supports internal redirection, partials and a file naming convention that allows resources to be hidden from direct requests.

## Starting Malifi

Malifi is Connect middleware.  Add it to Connect as you would with any other middleware.  Malifi expects one parameter, the name of the root directory of the site to be served, or the root directory of a site common to all sites to be served. This will be referred as the common site.  An optional second parameter allows overriding the default metadata, a topic addressed later in this document.

```javascript
app= connect.createServer()
app.use(malifi(__dirname+'/mysite'))
app.listen(port)
```

Malifi supports multiple sites.  Although only one site's root directory is defined at startup, a file in that site can define other sites and rles for routing requests to the right site, each of which may have its own filesystem root.  See the `multiple site support` section for more details.

## Serving a request

A brief overview of how an incoming request is served introduces a number of topics that will be described in fuller detail later in this document.

When a request is received, Malifi:

* Parses the URL, extracting the file extension, if any, the base name without extension and the site-relative path to files that might serve the request.
* Using the hostname (and perhaps other properties of the request) determines which site is to serve the request.  The site lookup process also results in a prioritied list of directories (the site stack) in which files matching the request will be sought.  Not only are multiple sites supported, but also a form of site inheritance through the site stack.  For any given "site", the site stack goes from most general (the base site that is built into Malifi and common to all Malifi installations) to the most specific.
* Metadata is obtained for the chosen site and path.  Metadata includes configuration information and may include any other data that remains the same from one request to another for a given URL.  The original purpose of metadata was to hold information like a resource's title or whether a user must be authenticated to access it, but it's turned out to be a much richer concept.  Metadata for a given request inherits from metadata from each of the directories in the path to the resource as well as all the sites in the site inheritance list.  All metadata is ultimately based upon the Malifi's default metadata.  Metadata definitions are optional at all levels: if present, they will expand the inherited metadata; if not present metadata will simply be inherited.
* A new object is created and added to the request object.  This new object will contain references to the metadata, the site stack and the parsed URL, path and host.  This object can be accessed as `<req>.malifi`.  By default, an alias named `<req>._` is also added.  The underscore alias is defined in the default metadata and, like anything else in the metadata, may be disabled or changed for any site or any directory within a site.
* The main action is called.  It performs some basic checks and begins a cascade of delegations to more specialized actions.
* If `meta.preempting_router_` is defined, the function it references is called by the main action.  A preempting router may preempt or supplement Malifi's native routing, such as to parse variables from the URL.  That router may also simply pass the request on to the `next` function so that it is handled by Malifi's default filesystem-based routing.  See the `preempting router` section for more information.
* The main action will also enforce hiding of files and directories whose names start with or end with an underscore or start with a dot.  A request for such a hidden resource will result in a "not found" condition.  By default, when a request is not found, the request will be passed to the next Connect middleware, but if a custom 404 handler is enabled, a `404 Not Found` response will be returned.
* All files matching the request are found.  Matching files are those whose name, minus rightmost extension, relative to a site root directory matches the relative URL. Matching files are found relative to every directory in the site stack.  The matching files are organized by site and by remaining extension, if any.  Any directories whose path matches the request are also found and indexed by a slash rather than an extension.
* Matching files from different sites having the same extension are merged.  For any given extension (or no extension), the name of the file from the most specific site in the site stack is retained.  The result is a set of files that may serve the request, with files from more specific sites overriding those from more general sites.
* The main action then delegates to whatever action handler is defined to perform the next step.  The default that is established in the base metadata is an action handler that delegates to yet another action handler based upon the HTTP verb.  Since this next step is defined in metadata, as is the main handler, it can be changed at any point.  The HTTP verb switching action delegates, in turn, to yet another action handler, such as one that delegates based upon URL extension, so that a request for a .PDF or a .CSS might get different treatment than a request without an extension.  That handler, in turn, might delegate to a series of actions which will either serve the request if expected conditions, such as a static resource or a template exist or pass the request on to the next action in the series.  Again, since each of these delegations is based upon metadata attributes, a request might be handled differently in one site as opposed to another or even from one directory to another.  Also, since the actions are broken into a series of distinct small steps, it is easy to substitute a new handler for one that does not do exactly what you would want it to do.  The community is invited to contribute new and improved handlers.

## Naming conventions

To avoid namespace collisions, file and directory names starting with an underscore should be considered reserved.  There are a few that currently have special meaning to Malifi and others could be defined in the future.  Files whose names start with an underscore are also by default hidden and will not be served in response to a corresponding URL.

File and directory names that end with an underscore are also by default hidden, but are otherwise not reserved.  This convention allows defining things like partials, page variants or responses that are not externally addressable and which would be adjacent to the page they are associated with in a directory listing.

Malifi also, by default, enforces the convention that any file or directory name starting with a dot is hidden.

These conventions are enforced by application of a regular expression defined as the forbiddenURLChars_ property of the metadata.  As with any other metadata property, this may be overridden.

The following reserved file names are defined at this time:
- _default: default metadata or resource for a directory.  Similar to the common convention of serving index.html when a URL refers to a directory.  The default metadata applies to all resources in that and directory and its subdirectories.
- _root: exports the absolute path to the project root or other directory from which any and all required files can be addressed.
- _siteroot: exports the path to the site's root directory, allowing relative addressing to the site's files, especially helpers.  Defining a _siteroot module in a subdirectory allows any module within a subdirectory to locate the root without each module having to count out the proper number of `../` segments.
- _sites: _sites.js (or _sites.coffee) is an optional file that directs requests to the next site layer.
- _helpers: additional supporting code for the modules of a site or a subdirectory.

## req.malifi (alias req._)

Whenever a request is received by Malifi, it adds an property named malifi to the request object.  By default, a second reference is added identified by the underscore character.  The req.malifi object includes the following properties, and possibly more:

* host: parses `req.headers.host` into separate properties:
  * name (hostname without any port number)
  * port

* url: `req.url`, parsed and decoded:
  * raw: alias of `req.url`
  * parsed: the result of running `req.url` through Node's `url.parse` function with query string parsing enabled, including:
     * href
     * path
     * pathname
     * query
     * search
  * decoded_path: the result of `decodeURIComponent(parsed.pathname)`.  This is further broken down in `malifi.path` below

* path: breaks out several components of the current path:
    Given a URL of `//localhost//zyx/abc.def.txt`:
    <table>
        <tr><th>path.relative</th><td>/zyx/abc.def.txt</td></tr>
        <tr><th>path.relative_base</th><td>/zyx/abc.def</td></tr>
        <tr><th>path.base</th><td>abc.def</td></tr>
        <tr><th>path.dot_extension</th><td>.txt</td></tr>
        <tr><th>path.extension</th><td>txt</td></tr>
    </table>

* meta: the metadata for the requested resource.  See the `metadata` section for more information.

* site_stack: A list of fully-qualified names of the root directories of all sites that are to be included when attempting to fulfill a request.  The first directory is that most specific to the request and the request will be served from files located in that directory if possible.  The final directory in the list will always be `<malifi>/base-site`, the system default site.  The site stack will always name at least two directories.

* files: all files matching the URL.  This is an object where each attribute is the file's extension and the value of the attribute is the file's fully-qualified name.  An action handler can often determine if it can support the request by determining if this object includes extensions needed for its action.  For example, an action handler that simply hands over a request to a module would check if this object includes either a `js` or a `coffee` attribute and, if so, invoking the module the referred to by that attribute.  This object is an accumulation of files from all site layers where a file in a more specific layer overrides one with the same extension from a more general layer.

* find_files: a method that populates `malifi.files` and `malifi.matching_files_by_site`.  It is an asynchronous function that only returns when all sites in the site stack have been examined.  This function is called by the main action handler but is exposed here so that replacement action handlers can use it.

* matching_files_by_site: an intermediate object added to malifi by the `find_files` method.  It contains all the files and directories that match the resource name for each site, even those that are overridden by a file with the same extension from a more specific site.  `malifi.files` is the result of a priortized merging of the contents of this object.

* connect_handler: a link back to the handler that receives requests from Connect.  Used for reinserting requests, such as for rerouting and partials.

* next_middleware_layer: the original `next` function that was  passed into Malifi when Malifi first started processing the request.  Some action handlers may send a different `next` function to action handlers it calls, such as one that calls a series of action handlers.  Calling this function will cause the request to be forwarded to the next middleware layer even if the normal path might be to pass a request on to the next action handler in a series.

## Multiple site support

Malifi supports multiple sites and the ability for sites to inherit resources.  One process can thus serve several domains and skinning is natively supported.  Even when only one domain without a separate skin layer is being served, that site inherits from Malifi's base site.

Malifi expects the name of the root directory of a site (the original directory) as an argument at startup.  If there is a file named `_sites.js` (or `_sites.coffee`) (the _sites module) in that directory, it will be consulted for paths of the root directories of other sites and for routing requests to those directories as they are received.

The _sites.js module should export two things:

* lookup: a function that for any given request will return the path that will
  serve as a root for that request.  Lookup is invoked so that `this` refers to
  a partially constructed `req.malifi` that contains only `host` and `url` properties
  and will also receive the usual `req,res,next` set of arguments.  Most commonly,
  lookup will map `this.host.name` (`@host.name` in CoffeeScript) to the
  path serving that hostname and return that path.  In that common case `lookup`
  would not need to reference the `req` argument.  A skin might instead select
  a site and return its path based upon user or session values.
* paths: an array containing all the paths that might be returned by the lookup
  function.  That list is used to preload metadata and modules.  It must include
  all paths that could be returned by the lookup function.

Any of the site root directories referenced by the _sites module may, in turn, also contain a _sites module, resulting in a directed graph of sites.  When processing a request, the orginal directory is checked first.  If it contains a _sites module, its lookup function will be called.  If the directory returned by the lookup function also contains a _sites module, its lookup function will also be called.  This continues until reaching a directory that does not include a _sites module.

When traversing the graph, a stack is initialized with the base site that is canned into Malifi at `<malifi directory>/base-site`.  Each directory visited is then added to the top of the stack.  The resultant stack thus starts at the top with the final, site-specific directory, goes back through each of the directories that contained a _sites module along the way and ends with the base site.  This site stack is then reversed and visited when looking for files to service a request.  The site stack also defines metadata inheritance.  Since the base site is always in the site stack, there are always at least two site layers, with defaults provided by the the base site.

If the lookup function returns its own directory or returns null or undefined, the result is the same, for that request, as if there were no _sites module in that diectory.  That directory will be at the top of the site stack.

For example, when the tests are run, Malifi is initialized with `<malifi directory>/test/sites/common` as an argument.  `test/sites/common` includes a `_sites.coffee` file.  When a request is received for localhost, the `lookup` method returns `<malifi directory>/test/sites/background`.  The background directory contains another `_sites.coffee` file, which returns `<malifi directory>/test/sites/foreground` when servicing a request for localhost.  The resultant site stack is:
```
<malifi directory>/test/sites/foreground
<malifi directory>/test/sites/background
<malifi directory>/test/sites/common
<malifi directory>/base-site
```

In this test environment, the `foreground` site is considered most specific to the request and `base-site` most general (it is shared by all sites using the same version of Malifi).  When a request is received, each of these directories will be scanned for files matching the request.  If files with the same extension (a directory or a file exactly matching the request are special case 'extensions') are found, the one from the most specific site would override those from a less specific site.  For example, the base site includes a module, `favicon.ico.coffee` that will, by default, serve a request for `favicon.ico`.  If another file having the same name were found in the background site, it would override that default, serving an icon more specific to that site.  Another file with the same name in the foreground site would likewise override the one in the background site, perhaps producing an icon that is specific to a given skin.

## Metadata

The original idea of metadata was to specify and make available information about a page or resource such as its name (perhaps needed by another resource when creating breadcrumb navigation) or whether authorization is required to access the resource.  But it soon became apparent that it could hold much more information, including configuration information for Malifi itself.  Metadata can include just about any immutable value and, depending upon where it is defined, may pertain to the entire server, a site, a directory within a site or an individual file or resource.

The metadata for any directory is specified in a `_default.meta.js` (or `_default.meta.coffee` or `_default.meta.json`) file.  Malifi default metadata is defined in `<malifi directory>/base-site/_default.meta.coffee`.  A default value for all metadata recognized by Malifi is defined there and comments in that file document each of those metadata properties.  This metadata is common to all Malifi installations of the same version.  Metadata property names ending with an underscore are reserved for malifi and its extensions.  Extension property names start with "ext_", followed by the extension's npm package name and an underscore and end with an underscore. For example, metadata for a package named "foo" might be named `ext_foo_something_` or `ext_foo_something_else_`.

Malifi is initialized by passing the root directory of a site (the common site) to the function exported by the <malifi directory>/index.js module.  That function also accepts an optional second parameter object.  If an optional second parameter is provided, the Malifi default metadata will be extended by the properties of the second parameter object.  The result will include all properties present in one or the other metadata objects with those in the second parameter object overriding any corresponding property in the Malifi default metadata.  When extending metadata, a property is deleted if overridden by a null value.

If there is a `_default.meta` module in the directory provided as the first parameter (the common site root directory), this will extend the result of the merge of the second parameter to arrive at the default server-wide metadata.

If multiple sites are defined, as each site stack is built, the `_default_meta` from the root directory of each site, if present, similarly extends the server-wide metadata, so that the metadata for any given site is based upon the server-wide metadata extended by that of any intermediate sites and finally of the site at the top of the site stack.  In the test case, for example, the server-wide metadata is the `base-site` (Malifi default) metadata, extended by the second parameter options and then extended again by the `common` site.  This server-wide default metadata is then exteded by the `background` site's metadata and the `foregroud` site's metadata to produce the default metadata for the foreground site.

Each subdirectory of a site's root directory similarly inherits the root's metadata merged with any `_default.meta` module encountered in that subdirectory.  This continues for each subdirectory of a subdirectory, so that any given subdirectory inherits the metadata of the directory above it merged with any `_default.meta` module found in that subdirectory.

Finally any given resource may include a `<resource-name>.meta.js` (or .coffee or .json) module, which will be merged with the containing directory's metadata to arrive at that resource's metadata.  The resource's main module (<resource-name>.js or <resource-name>.coffee) may also export a 'meta' property which is treated the same (see `test/sites/foreground/sub/addmeta.coffee` for an example). If metadata is not defined for any resource (or any directory) it inherits the metadata of the directory it is contained in.  Thus every resource has associated metadata that is ultimately based upon the server-wide metadata.  Whenever malifi receives a request, the metadata that best matches the request, possibly by paring back directory layers, will be loaded into `req.malifi.meta`.

If the metadata module is a .js or .coffee file, it may simply export an object containing the metadata. An example of this can be found at `<malifi directory>/base-site/_default.meta.coffee`.  It may alternatively export a function taking one parameter.  That parameter is the metadata being inherited.  It is thus possible to base the value of any given metadata attribute on the value it inherits or even dependent upon other metadata properties.  An example of this can be found at `<malifi directory>/test/sites/common/_default.meta.coffee`.

If we think of inheritance by a subdirectory of its parent directory's metadata as horizontal inheritance, metadata can also be inherited vertically, from a more general site to a more specific site.  Vertical inheritance has already been described with regards to each site's `_default.meta`, but metadata can also be inherited vertically for any directory or resource in a site.  A given resource's metadata thus is the result of taking the site default metadata, extending it by the metadata of any intermediate directories in inherited sites and the most specific site and then extending that by any common metadata for a requested resource and extending that by any metadata specific to the resource in the most specific site.  Metadata inheritance goes up the site stack at the root directory level, goes up the stack again for each intervening directory and finally up the stack for the resource itself.  If no metadata file or resource is found at any given extension point, the metadata from the preceding extension point is inherited unchanged.

All metadata is preloaded in a single synchronous operation when the server is initialized and should be considered an immutable resource.

## Action handlers

Action handlers are structured the same as Connect middleware.  Each is a module that returns a method that takes the request and response objects as arguments as well as a `next` function.  It may serve the request by sending messages to the response object.  If an error is encountered they may call the `next` function with an error object as an argument.  Or it might pass the request on to the next action handler by calling the `next` function with no argument.

Action handlers may also call another action handler to service the request.  Malifi provides an action handler, for example, that delegates a request to different handlers based upon the HTTP method.  Another similarly delegates based upon the extension, if any, of the URI.  Malifi also includes an `action_series` action handler that passes a request through a series of action handlers until one ends up serving the request.  In this case, `next` forwards the request to the next action handler rather than the next middleware layer.

There may be cases where a request is being served by one action handler in a series, but it determines that no other action handlers should handle the request.  Most commonly, this would be because it determined that no suitable file exists for serving the request.  In that case, instead of calling `next` the action handler can call the `req.malifi.next_middleware_layer` function.

When a `GET` request is received, the default set of handlers delegates the request to different action handlers based upon the request's extension via a map defined at `meta.get_action_map_`:
  * If the request maps to a directory in filesystem `get_action_map_` is indexed by `'/'`.
  * If the request includes an extension, `get_action_map_` will be indexed by that extension.
  * If the request includes an extension but `get_action_map_` does not include a matching index, the method object will be indexed by `'*'`.
  * If the request does not include an extension, the method object is indexed by an empty string.
Whatever the index, the value is either another action handler or the name of a metadata attribute that references an action handler.  In some cases, that action handler delegates to a series of additional action handlers.

## HTTP method support

If the HTTP method is something other than GET or HEAD, Malifi's convention is to append the method, converted to lower case, as an extra extension before looking for matching files.  A POST to `http://example.com/a` would map to `a.post.js` or `a.post.coffee`, for example.  A common case might be that a GET of `/a` would produce a form that when filled out is POSTed to the same URL, '/a'.  These two requests, GET and POST, might be served by the files `a.js` (and perhaps `a.template`) and by `a.post.js` respectively.  The files would be close together in an alphabetic list of files.

Since this convention is implemented in action handlers, it can be changed by simply substituting different handlers in the metadata.

Malifi does not parse request bodies.  For POST, PUT and other methods that include a request body to work, `Connect's bodyParser` or equivalent middleware must preceded Malifi in the middleware chain.

## Internal redirection (rerouting) and partials

Malifi supports internal redirection (rerouting) and partials.  Internal redirection works much like ordinary redirection but does so silently without any message exchange with the client.  A request for `/foo` ends up served by the `/bar` resource.  This might occur, for example, if the response to a given URL varies depending upon whether the user is logged in.  Internal redirects bypass the hiding rules, so that in the example above a request for `/a` might be rerouted to `/a_logged_` if the user is logged in (because of the trailing underscore, a request for `/a_logged_` would normally be rejected as not found).

Malifi also supports partials.  While rendering the requested resource, an internal request may be made for another resource to be inserted inside the request.  The hiding rules are also not enforced for partials.  The default Malifi implementation accumulates the result into a buffer and sends the buffer to a callback, but does not otherwise alter the result, such as by stripping HTML and BODY tags.

Rerouting is achieved by sending the destination path, and optionally a hostname, to `req.malifi.meta.reroute_()`.  This returns an object that reroutes to that resource.  Send req,res,and next to that reroute object to actually perform the reroute.

A partial is obtained sending the destination path and optionally a hostname to `req.malifi.meta.partial_()`.  This returns an object that will fetch that resource and accumulate the result.  Send `req`,`res`,`next` and a callback to that partial-fetching object to actually fetch the partial.  A buffer containing the result will be sent to the callback when the partial has completed.  If there is an error, including a HTTP status code other than 200, `next()` will be called and the callback will never be invoked.  Any headers sent by the partial, other than the status code, will be ignored.

The default action handlers will externally redirect a URL that is of a directory but lacking a trailing slash to the same URL with a trailing slash.  If the URL includes a trailing slash, a resource named _index will be served (such as _index.js or _index.coffee).

## Preempting Router

Malifi's default routing maps a URL to resources in the filesystem, much as a server serving up static web pages would do.  This default routing may be superceded or supplimented by defining a router in `meta.preempting_router_`.  The router should have the same interface as any other action handler, or Connect middleware.  The router is called with the usual request, response and next arguments.  If the router does not recognize the request, it can simply pass the request on to the `next` function to allow the native filesystem-based router.  The router typically attempts to match the request against one or more regular expressions or similar more specialized expressions, possibly extracting variables from the URL or otherwise parsing the URL.  It may then serve the result directly, invoke action handlers or save the variables in the `request` object, and redirect by calling `meta.reroute_`.

Since a preempting router is defined in metadata, preemptive routing can be limited to specific sites or directories within a site.  If a directory's default_.meta specifies a preempting router, any URL that includes that directory will be run through that router unless a resource within that directory or a subdirectory has metadata that does not include the router.  Any directory can thus be made into a virtual directory.

Assuming that the router calls `next` if it does not match the request, an unmatched request will fall through to the default filesystem-based router.  This would allow a directory to include both virtual resources and concrete ones.  In the test foreground site, for example, there is a `date` directory that will parse a string in the form `/date/mm/dd/yyyy` into its component parts.  But the `date` directory also includes a `today.txt` resource which will be served when the URL is `/date/today` even though `today` is not recognized by the regular expression.

Malifi includes two simple preempting routers.  The `virtual_directory_router` turns any directory into a virtual directory.  All URL elements beyond the directory will be placed into an array stored at `request.args` and the request will then be rerouted to the URL in the `redirect_to` argument.  A directory can be turned into a virtual directory by setting the `preempting_router_` attribute to the `virtual_directory_router` in the directory's `_default.meta` module and including the URL to which requests are to be redirected in the argument.
The `regex_router` similarly turns any directory into a virtual directory, but takes two arguements, a regular expression and the destination URL.  Requests are only handled if they match the regular expression and the regular expression allows greater control over what is captured from the URL and placed in `request.args`.

Additional routers may be defined.  The community is invited to contribute more sophisticated, creative or specialized ones.

## Template Support

A design goal of Malifi is to not favor any specific template system, but rather to provide a platform that can work with multiple template engines, including the ability to use multiple template systems in a given site.Because of a preexisting dependency upon `Underscore`, a reference implementation of templating using the Underscore engine is included, but it is intended that supplemental projects will provide adapters to a number of different engines.  Implementing adapters as separate projects avoids dependencies on engines that are otherwise not required for a given application. The community is invited to contribute additonal adapters.

To use a template, a page's `.js` or `.coffee` module first creates a context object and populates it with data and perhaps functions needed by the template.  It then calls `req.malifi.render` with the requested MIME type and context object.  The render function passes the request to the metadata `renderer_` function.  By default, this is the renderer defined in `lib/renderer.coffee`.  That renderer uses the metadata `template_map_` to select a template engine-specific adapter for the requested MIME type, and the set of files matching the request's URL.

A template engine-specific adapter is an object that has either a `compile_file(req,res,filename,when_compiled)` or a `compile_string(req,res,template,when_compiled)` function.  If the compile_file function exists, it will be called with the name of the template file, otherwise Malifi will read the template file's content and pass it to the `compile_string` function.  If the targeted template engine does not include a compilation phase.  The compilation functions may simply retain the file name or template string and return a `when_compiled` function that uses the retained name or string.

When `compile_string` or `compile_file` is complete, it must invoke the `when_compiled(err,compiled)` callback function.  Unless there is an error, the `compiled` argument must be an object that includes a
`render(context,when_rendered)` function that should render the compiled template using the given context and then call the `when_rendered(err,result)` callback function with the rendered result.

Because the template map is defined in metadata, it can vary from one part of a site to another and the template to be used can even be specified from one page to another.  If templates used with different template engines have different file extensions, engines may be selected based upon extension.

### Layout Templates

A template engine-specific adapter may include support for wrapping its output in a layout. The layout may be rendered by a different template engine, or indeed by Javascript code.

Since some layout engines include their own layout support, layouts are defined per template engine.  A markdown engine, for example, may produce an HTML fragment that needs to be wrapped in html and body tags whereas a Jade template on the same site might extend a base Jade template.  In this case, the layout used with markdown output might be a Jade template that extends the same base template used by Jade templates.

If the `compiled` argument above incldues a `layout_path` attribute, the template result will be placed in `req.layout_context.body` and the request will be redirected to the path given by the `layout_path` attribute.  `req.layout_context.context` will also be set to the template's context object.

Typically, the layout will consist of a javascript module that builds a context object, given `req.layout_context.body` and `req.layout_context.context` and renders an associated template file.  The module may also refer to `req.from_req` to access the original request object, including its `malifi` and `meta` objects.

The [Malifi](https://github.com/randymized/malifi) wiki includes [a layout template example](https://github.com/randymized/malifi/wiki/Layout-template-example).

### Bare templates

A template without a corresponding code module is called a bare template.  Fundamentally a bare template is like a static HTML file except that it is rendered on demand and may involve translation from the template syntax to the output format, such as HTML.

It is also possible to define a default context function by assigning a function to `default_context_fn_` in the metadata.  That function will be called and the object it returns will be used as context when any template is rendered without a context (with a null context object).  A default context function might populate the context with values taken from the URL, the request object, metadata, the session object or some other available information.

## License

(The MIT License)

Copyright (c) 2012 Randy McLaughlin &lt;8b629a9884@snkmail.com&gt;

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.