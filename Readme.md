# malifi

MAny LIttle FIles.
A Connect layer where requests are routed to files in a directory whose structure reflects that of the URL.
Malifi organizes all files that support a given page, such as code, template, CSS and supporting javascript together.
Routing is, by default, implicit, although explicit routing is also possible.

For example, a URL of http://example.com/foo/bar might be served by HTML from a file located at `<site-root>/foo/bar.html` or from HTML generated by `<site-root>/foo/bar.js` or by that file plus a Jade template (more about template system support below) at `<site-root>/foo/bar.jade`.
http://example.com/foo/bar.css might be served from a CSS file at `<site-root>/foo/bar.css` or at `<site-root>/foo/bar.less` or at `<site-root>/foo/bar.sass`.

Basically the resources for any given request are served from many specifically focused files where the organization of the files allows readily mapping a URL to the files supporting that URL and where the files that serve that request are in close proximity rather than scattered about the filesystem.

Some other key features of Malifi are:

* Multiple site (and layer) support: each domain served may have its own filesystem tree.
  Provision also exists for pages and resources that are common to one or more
  site, establishing an inheritance heirarchy for sites.  A skin may inherit from
  and override a site's default resources.
* Metadata for each site, directory and page.  Global metadata is inherited by
  each site.  Site metadata is inherited by its first-level directories.
  Subdirectories inherit the metadata of their parent directory.  A page
  inherits the metadata of its parent directory.  At each step, metadata
  may be overridden or redefined.  Malifi configuration is maintained in the
  metadata, but it may be freely expanded to include additional data.
* Support for internal redirection and partials.

## Starting Malifi

Malifi is Connect middleware.  Add it to Connect as you would with any other middleware.  Malifi expects one parameter, the name of the root directory of the site to be served, or the root directory of a site common to all sites to be served. This will be referred as the common site.  An optional second parameter allows overriding the default metadata, a topic addressed later in this document.

```javascript
app= connect.createServer()
app.use(malifi(__dirname+'/mysite'))
app.listen(port)
```

Malifi supports multiple sites.  See the multiple site support topic to learn how you can specify one site root at startup but end up supporting multiple sites, each of which may have its own filesystem root.

## Serving a request

A brief overview of how an incoming request is served introduces a number of topics that will be described in fuller detail later in this document.

When a request is received, Malifi:

* Parses the URL, extracting the file extension, if any, the base, name without extension and the site-relative path to files that might serve the request.
* Using the hostname (and perhaps other properties of the request) determines which site is to serve the request.  The site lookup process also results in a prioritied list of directories (the site stack) in which files matching the request will be sought.  Not only are multiple sites supported, but also a form of site inheritance through the site stack.  For any given "site", the site stack goes from most general (the base site that is built into Malifi and common to all Malifi installations) to the most specific.
* Metadata is obtained for the chosen site and path.  Metadata includes configuration information and may include any other data that remains the same from one request to another for a given URL.  The original purpose of metadata was to hold information like a resource's title or whether a user must be authenticated to access it, but it's turned out to be a much richer concept.  Metadata for a given request inherits from metadata from each of the directories in the path to the resource as well as all the sites in the site inheritance list.  All metadata is ultimately based upon the Malifi's default metadata.
* A new object is created and added to the request object.  This new object will contain references to the metadata, the site stack and the parsed URL, path and host.  This object can be accessed as `req.malifi`.  By default, an alias named `req._` is also added.  The underscore alias is defined in the default metadata and, like anything else in the metadata, may be disabled or changed for any site or any directory within a site.
* The main action is then called.  It selects and invokes actions that may serve the request.  The remainder of the steps described herein are performed by the default main action.
* Files and directories whose names start with or end with an underscore or start with a dot are hidden.  A request for such a hidden resource will result in a "not found" condition.  By default, when a request is not found, the request will be passed to the next Connect middleware, but if a custom 404 handler is enabled, a `404 Not Found` response will be returned.
* All files matching the request are found.  Matching files are those whose name, minus extension, relative to a site root directory matches the relative URL. Matching files are found relative to every directory in the site stack.  The matching files are organized by site and by extension.  Any directories whose path matches the request are also found and indexed by a slash rather than an extension.
* Matching files from different sites having the same extension are merged.  For any given extension (or no extension), the name of the file from the most specific site in the site stack is retained.  The result is a set of files that may serve the request, with files from more specific sites overriding those from more general sites.
* An action handler is chosen and invoked to serve the request.  Action handlers may pass the request to another action handler based upon criteria like HTTP method, URL extension, or the extensions of files matching the request.  An action handler may also implement a cascade of other action handlers, passing the request from one handler to the next until one serves the request.  In the end, an action handler may serve a file that matches the request, invoke a module that matches the request, invoke a module and apply the results to a template that also matches the request, or pull together whatever other resources are need to serve the request.

## Naming conventions

To avoid namespace collisions, file and directory names starting with an underscore should be considered reserved.  There are a few that currently have special meaning to Malifi and others could be defined in the future.  Files whose names start with an underscore are also by default hidden and will not be served in response to a corresponding URL.

File and directory names that end with an underscore are also by default hidden, but are otherwise not reserved.  This convention allows defining things like partials, page variants or responses that are not externally addressable but are adjacent to the page they are associated with.

Malifi also, by default, enforces the convention that any file or directory name starting with a dot is hidden.

These conventions are enforced by application of a regular expression defined as the forbiddenURLChars_ property of the metadata.  As with any other metadata property, this may be overridden.

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
    
    The site_root, full, and full_base properties will reflect the root of the site currently being examined and thus may vary during processing of a request.  These are the properties you would normally use for building names of files that might serve the request.

* files: all files matching the URL.  This is an object where each attribute is the file's extension and the value of the attribute is the file's fully-qualified name.  An action handler can often determine if it can support the request by determining if this object includes extensions needed for its action.  For example, an action handler that simply hands over a request to a module would check if either this object includes a `js` or `coffee` attribute and, if so, invoking that module.  This object is an accumulation of files from all site layers where files in a more specific layer overrides one with the same extension from a more general layer.

* meta: the metadata for the requested resource.

* meta_lookup:  A function that will return the metadata for any fully-qualified path.  The `meta` and property was obtained using this function.  A request for a directory's metadata should include a trailing slash.

* site_stack: A list of fully-qualified names of the root directories of all sites that are to be included when attempting to fulfill a request.  The first directory is that most specific to the request and the request will be served from files located in that directory if possible.  The final directory in the list will always be `<malifi>/base-site`, the system default site.  The site stack will always include at least two properties.

* matching_files_by_site: All files matching the request, organized by site.  This object contains one object for each path in the site stack that contains files matching the request.  The objects are keyed by the site root path.  Each of those objects are indexed by extension with each attribute being the file's fully qualified name.  A directory matching the URL will be indexed by a slash.  A file that matches the request without any extension will be indexed by an empty string.  This is the full list of files matching the request before being merged to a single object containing the most specific file of each extension.

* find_files: a method of malifi.  Given a directory and the name of a resource, finds all files in the given directory of each site that matches `resource_name.*` or `resource_name`.  An object will be returned that maps file extensions to file names. If a file's name exactly matches the resource name, the attribute name will be an empty string unless the matching name is that of a directory, in which case the name will be indexed by a slash. 
Where there are resources with the same extension in different sites of the site stack, the result for each extension will include the file which from the most specific site containing a file with that extension in the site stack.  The find_files method will also add malifi.matching_files_by_site to `req.malifi`(see below).

* matching_files_by_site: an intermediate object added to malifi by the `find_files` method.  It contains all the files and directories that match the resource name for each site.  The find_files method returns an object that merges each site in this object into a single object that references the most specific file of each extension.  This object references all files found, including those which were overridden by one of the same extension from a more specific one.

* connect_handler: a link back to the handler that receives requests from Connect.  Used for reinserting requests, such as for rerouting and partials.

* next_middleware_layer: the original `next` function that was  passed into Malifi when Malifi first started processing the request.  Some action handlers may send a different `next` function to action handlers it calls, such as one that calls a series of action handlers.  Calling this function will cause the request to be forwarded to the next middleware layer even if the normal path might be to pass a request on to the next action handler in a series.

## Multiple site support

Malifi supports multiple sites and the ability for sites to inherit resources.  One process can thus serve several domains and skinning is natively supported.  Even when only one domain without a separate skin layer is being served, that site inherits from Malifi's base site.

Malifi expects the name of the root directory of a site (the original directory) as an argument at startup.  If there is a file named `_sites.js` (or `_sites.coffee`) (the _sites module) in that directory, it will be consulted for paths of the root directories of other sites and for routing requests to those directories as they are received.

The _sites.js module should export two things:

* lookup: a function that for any given request will return the path that will
  serve as a root for that request.  Lookup is invoked so that `this` refers to
  a partially constructed `req.malifi` that contains only `host` and `url` properties
  and will also receive the usual `req,res,next` argument.  Most commonly, 
  lookup will map `this.host.name` (`@host.name` in CoffeeScript) to the
  path serving that hostname and the req argument can be ignored.  A skin might be
  selected based upon user or session values.
* paths: an array containing all the paths that might be returned by the lookup
  function.  That list is used to preload metadata and modules.  It must include
  all paths that could be returned by the lookup function.

Any of the site root directories referenced by the _sites module may, in turn, also contain a _sites module, resulting in a branching tree of sites.  When processing a request, the orginal directory is checked first.  If it contains a _sites module, its lookup function will be called.  If the directory returned by the lookup function also contains a _sites module, its lookup function will also be called.  This continues until reaching a directory thatdoes not include a _sites module.

Each directory that contains a _sites module is added to a stack of sites that are to be visited when looking for files to service a request.  This stack starts with the final, site-specific directory, goes back through each of the directories that contained a _sites module along the way and ends with the base site that is canned into Malifi at `<malifi directory>/base-site`.  Since the base site is always in the site stack, there are always at least two site layers.

If the lookup function returns its own directory or returns null or undefined, the result is the same, for that request, as if there were no _sites module in that diectory.  That directory will be at the top of the site stack.

For example, when the tests are run, Malifi is initialized with `<malifi directory>/test/sites/common` as an argument.  `test/sites/common` includes a `_sites.coffee` file.  When a request is received for localhost, the `lookup` method returns `<malifi directory>/test/sites/background`.  The background directory contains another `_sites.coffee` file, which returns `<malifi directory>/test/sites/foreground` when when servicing a request for localhost.  The resultant site stack is:
```
<malifi directory>/test/sites/foreground
<malifi directory>/test/sites/background
<malifi directory>/test/sites/common
<malifi directory>/base-site
```

In this test environment, the `foreground` site is considered most specific to the request and `base-site` most general (it is shared by all sites using the same version of Malifi).  When a request is received, each of these directories will be scanned for files matching the request.  If files with the same extension (a directory or a file exactly matching the request are special case 'extensions') are found, the one from the most specific site would override those from a less specific site.  For example, the base site includes a module, `favicon.ico.coffee` that will, by default, serve a request for `favicon.ico`.  If another file having the same name were found in the background site, it would override that default, serving an icon more specific to that site.  Another file with the same name in the foreground site would likewise override the one in the background site, perhaps producing an icon that is specific to a given skin.

## Metadata

The original idea of metadata was to specify and make available information about a page or resource such as its name (perhaps needed by another resource when creating breadcrumb navigation) or whether authorization is required to access the resource.  But it soon became apparent that it could hold much more information, including configuration information for Malifi itself.  Metadata can include just about any immutable value and, depending upon where it is defined, may pertain to the entire server, a site, a directory within a site or an individual file or resource.

The metadata for any directory is specified in a `_default.meta.js` (or `_default.meta.coffee` or `_default.meta.json`) file.  Server-wide default metadata is defined in `<malifi directory>/base-site/_default.meta.coffee`.  A default value of all metadata recognized by Malifi is defined there and comments in that file describe each of those metadata properties.  Metadata properties whose name ends with an underscore are reserved for malifi and its extensions.

When Malifi is initialized, the root directory of a site to be served must be provided as the first parameter.  If an optional second parameter is provided, it will be merged with the base-site metadata so that any of the argument options override base-site metadata.  If there is a `_default.meta` module in common site's root directory (the directory provided as the first parameter), this will be merged with the result of the options merge to arrive at the server-wide metadata.

If multiple sites are defined, as each site stack is built, the `_default_meta` from the root directory of each site, if present, is similarly merged with the server-wide metadata, so that the metadata for any given site is based upon the server-wide metadata merged with any intermediate sites and the site at the top of the site stack.  In the test case, for example, the server-wide metadata is the `base-site` (Malifi default) metadata, merged with any options and then merged with the `common` site.  The `foregroud` site's metadata is the server-wide metadata merged with that of the `background` site and then with the `foreground` site.  

Each subdirectory of a site's root directory similarly inherits the root's metadata merged with any `_default.meta` module encountered in that subdirectory.  This continues for each subdirectory of a subdirectory, so that any given subdirectory inherits the metadata of the directory above it merged with any `_default.meta` module found in that subdirectory.

Finally any given resource may include a `<resource-name>.meta.js` (or .coffee or .json) module, which will be merged with the containing directory's metadata to arrive at the resource's metadata.  The resource's main module (<resource-name>.js or <resource-name>.coffee) may also export a 'meta' property which is treated the same (see test/sites/foreground/sub/addmeta.coffee for an example). If metadata is not defined for any resource (or any directory) it inherits the metadata of the directory it is contained in.  Thus every resource has associated metadata that is ultimately based upon the server-wide metadata.  This will be loaded when malifi receives a request into `req.malifi.meta`.

If the metadata module is a .js or .coffee file, it may simply export an object containing the metadata as `<malifi directory>/base-site/_default.meta.coffee` does.  It may alternatively export a function taking one parameter.  That parameter is the metadata being inherited.  It is thus possible to base the value of any given metadata object on the value it inherits or even dependant upon other metadata properties.  An example of this can be found at `<malifi directory>/test/sites/common/_default.meta.coffee`.

All metadata is preloaded in a single synchronous operation when the server is initialized.

## Action handlers

Action handlers are structured the same as Connect middleware.  They are a module that returns a method that takes the request and response objects as arguments as well as a `next` function.  If they may serve the request by sending messages to the response object.  If an error is encountered they may call the `next` function with an error object as an argument.  Or they might pass the request on to the next action handler by calling the `next` function with no argument.

Action handlers may also call another action handler to service the request.  The default action handlers that come with Malifi switch a request to different handlers based upon the HTTP method, for example, and that handler might in turn switch the request to different handlers depending upon whether the request includes an extension and what the extension is.  Malifi also includes an `action_series` action handler that passes a request through a series of action handlers until one ends up serving the request.  In this case, `next` takes the request not to the next middleware layer but rather to the next action handler.

There may be cases where a request is being served by one action handler in a series, but it determines that no other action handlers should handle the request.  Most commonly, this would be because it determined that no suitable file exists for serving the request.  In that case, instead of calling `head` the action handler can call the `req.malifi.next_middleware_layer` function.

When a `GET` request is received, the default handler switches the request to different action handlers based upon the request's extension:
  * If the request maps to a directory in the filesystem the method object is indexed by `'/'`.  
  * If the request includes an extension, the method object will be indexed by that extension.
  * If the request includes an extension but there is no index of the method object matching that extension, the method object will be indexed by `'*'`. 
  * If the request does not include an extension, the method object is indexed by an empty string. 

## HTTP method support

If the HTTP method is something other than GET or HEAD, Malifi's convention is to append the method, converted to lower case, as an extra extension before looking for matching files.  A post to `http://example.com/a` would map to `a.post.js` or `a.post.coffee`, for example.  A common case might be that a GET of `/a` would produce a form that when filled out is POSTed to the same URL, '/a'.  These might be served by the files `a.js` (and perhaps `a.template`) and by `a.post.js` respectively.  The files would be close together in an alphabetic list of files.

Since this convention is implemented in action handlers, it can be changed by simply substituting different handlers in the metadata.

Malifi does not parse request bodies.  For POST, PUT and other methods that include a request body to work, Connect's bodyParser or equivalent middleware must preceded Malifi in the middleware chain.

## Internal redirection (rerouting) and partials

Malifi supports internal redirection (rerouting) and partials.  Internal redirection works much like ordinary redirection but does so silently without any message exchange with the client.  A request for `/foo` ends up served by the '/bar' resource.  This might occur, for example, if the response to a given URL varies depending upon whether the user is logged in.  Internal redirects bypass the hiding rules, so that in the example above, a request for `/a` might be rerouted to `/a_logged_` if the user is logged in (because of the trailing underscore, a request for `/a_logged_` would normally be rejected as not found.  

Malifi also supports partials.  While rendering the requested resource, an internal request may be made for another resource to be inserted inside the request.  The hiding rules are also not enforced for partials.  The default Malifi implementation accumulates the result into a buffer and sends the buffer to a callback, but does not otherwise alter the result, such as by stripping HTML and BODY tags.

Rerouting is achieved by sending the destination path and optionally a hostname to `req.malifi.meta.reroute_()`.  This returns an object that reroutes to that resource.  Send req,res,and next to that reroute object to actually perform the reroute.

A partial is obtained sending the destination path and optionally a hostname to `req.malifi.meta.partial_()`.  This returns an object that will fetch that resource and accumulate the result.  Send req,res,next and a callback to that partial-fetching object to actually fetch the partial.  A buffer containing the result will be sent to the callback when the partial has completed.  If there is an error, including a HTTP status code other than 200 it will be sent to `next()` and the callback will never be invoked.  Any headers sent by the partial will be ignored.

The default action handlers will exteranlly redirect a URL that is of a directory but lacking a trailing slash to the same URL with a trailing slash.  If the URL includes a trailing slash, a resource named _index will be served (such as _index.js or _index.coffee).


## Template Support

Malifi does not favor any given template system.  In fact, to avoid dependencies on template systems that you do not intend to use, it does not support any templates out of the box.  Template system interfaces will be supported as separate projects and may come from multiple contributors.

## License 

(The MIT License)

Copyright (c) 2011 Randy McLaughlin &lt;8b629a9884@snkmail.com&gt;

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