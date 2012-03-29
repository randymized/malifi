
# malifi

MAny LIttle FIles.
A Connect layer where requests are routed to files in a directory whose structure reflects that of the URL.
Malifi organizes all files that support a given page, such as code, template, CSS and supporting javascript together.
Routing is, by default, implicit, although explicit routing is also possible.

For example, a URL of http://example.com/foo/bar might be served by HTML from a file located at `<site-root>/foo/bar.html` or from HTML generated by `<site-root>/foo/bar.js` or by that file plus a Jade template (more about template system support below) at `<site-root>/foo/bar.jade`.
http://example.com/foo/bar.css might be served from a CSS file at `<site-root>/foo/bar.css` or at `<site-root>/foo/bar.less` or at `<site-root>/foo/bar.sass`.

Basically the resources for any given request are served from many specifically focused files where the organization of the files allows readily mapping a URL to the files supporting that URL and where the files that serve that request are in close proximity rather than scattered about the filesystem.

Some other key features of Malifi are:

* Multiple site support: each domain served may have its own filesystem tree.
  Provision also exists for pages and resources that are common to one or more
  site, establishing an inheritance heirarchy for sites.  A skin may inherit from
  and override a site's default resources.
* Metadata for each site, directory and page.  Global metadata is inherited by
  each site.  Site metadata is inherited by its first-level directories.
  Subdirectories inherit the metadata of their parent directory.  A page
  inherits the metadata of its parent directory.  At each step, metadata
  may be overridden or redefined.  Malifi configuration is maintained in the
  metadata, but it may be freely expanded.
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
* Using the hostname (and perhaps other properties of the request) determines which site is to serve the request.  The site lookup process also results in a list of directories to check (the site stack) if the main site directory does not serve the request.  Not only are multiple sites supported, but also a form of site inheritance through the site stack.  Joining the root directory of a site with the site-relative path results in a fully qualified path that may be joined with extensions to arrive at the name of files that might serve the request.
* Metadata is obtained for the chosen site and path.  Metadata includes configuration information and may include any other data that remains the same from one request to another for a given URL.  The original purpose of metadata was to hold information like a resource's title or whether a user must be authenticated to access it, but it's turned out to be a much richer concept.  Metadata for a given request inherits from metadata from each of the directories in the path to the resource as well as all the sites in the site inheritance list.  All metadata is ultimately based upon the Malifi's default metadata.
* A new object is created containing references to the metadata, the site stack and the parsed URL, path and host and added to the request.  This object can be accessed as `req.malifi`.  By default, an alias named `req._` is also added.  The underscore alias is defined in the default metadata and, like anything else in the metadata, may be disabled or changed for any site or any directory within a site.
* The main action is then called.  It selects and invokes actions that may serve the request.  The remainder of the steps described herein are performed by the default main action.
* Files and directories whose names start with or end with an underscore or start with a dot are hidden.  A request for such a hidden resource will result in a "not found" condition.  By default, the request will be passed to the next Connect middleware, but if a custom 404 handler is enabled, a 404 Not Found response will be returned.
* All files matching the request are found.  Matching files are those whose path relative to a site root directory matches the relative URL. If removing the extension from a file's name matches the URL it is also considered a matching file.  Matching files are found relative to every directory in the site stack.  The matching files are organized by site and by extension.  Any directories whose path matches the request are also found and indexed by a slash rather than an extension.
* Matching files from each site that have the same extension are merged.  For any given extension (or no extension), the name of the file from the most specific site in the site stack is retained.  The result is a set of files that may serve the request with files from more specific sites overriding those from more general sites.
* An action handler, or list of action handlers, is selected based upon the request method (GET, POST, etc), and optionally the extension, if any, of the URL.  Action handlers are structured the same as Connect middleware and may either serve the request or pass the request on to the next level.  But here, the "next level" means the next action in the list of action handlers.  If all the actions in the list pass on the request (or if there is a single action handler), the process is repeated for next site in the site stack.  Only when all actions in the selected action handlers of each site in the site stack passes on the request does Malifi pass on the request.  If a custom 404 handler is defined, it will be invoked.  Otherwise the request is passed to the next Connect middleware level.  The request can also be punted to the next Connect middleware level without going through (short circuiting) all actions of all sites in the site stack by calling req.malifi.next_middleware_layer().


## Naming conventions

To avoid namespace collisions, file and directory names starting with an underscore should be considered reserved.  There are a few that currently have special meaning to Malifi and others could be defined in the future.  Files whose names start with an underscore are also by default hidden and will not be served in response to a corresponding URL.

File and directory names that end with an underscore are also by default hidden, but are otherwise not reserved.  This convention allows defining things like partials, page variants or responses that are not externally addressable but are adjacent to the page they are associated with.

Malifi also, by default, enforces the convention that any file or directory name starting with a dot is hidden.

These conventions are enforced by application of a regular expression defined as the _forbiddenURLChars property of the metadata.  As with any other metadata property, this may be overridden.

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

* find_files: a method of malifi.  Given a directory and the name of a resource, finds all files in the given directory of each site that matches resource_name.* or resource_name.  An object will be returned for which the attributes are named for the file's extension.  If the file exactly matches the resource name without any extension, the attribute name will be an empty string.  However, if the resource name exactly matches a directory's name, the attribute's name will be a slash.  Each attribute's value will be the file's fully-qualified name.
Where there are resources with the same extension in different sites of the site stack, the result will include the most specific file for each extension.  The find_files method will also add malifi.matching_files_by_site (see below).

* matching_files_by_site: an intermediate object added to malifi by the find_files method.  It contains all the files and directories that match the resource name for each site.  The find_files method returns an object that merges each site in this object into a single object that references the most specific file of each extension.  This object, then, exposes all matching files, even those overridden by a more specific one.

* connect_handler: a link back to the handler that receives requests from Connect.  Used for reinserting requests, such as for rerouting and partials.

## Multiple site support

Malifi supports multiple sites and the ability for sites to inherit resources.  One process can thus serve several domains and skinning is natively supported.  Even when only one domain without a separate skin layer is being served, that site inherits from Malifi's base site.

Malifi expects the name of the root directory of a site (the original directory) as an argument at startup.  If there is a file named `_sites.js` (or `_sites.coffee`) (the _sites module) in that directory, it will be consulted for paths of the root directories of other sites and for routing requests to those directories as they are received.

The _sites.js module should export two things:

* lookup: a function that for any given request will return the path that will
  serve as a root for that request.  Lookup is invoked so that `this` refers to
  a partially constructed `req.malifi` that contains only `host` and `url` properties
  and will also receive the usual `req,res,next` argument.  Most commonly, 
  lookup will map `this.host.name` (`@host.name` in CoffeeScript) to the
  path serving that hostname and the req argument can be ignored.
* paths: an array containing all the paths that might be returned by the lookup
  function.  That list is used to preload metadata and modules.  It must include
  all paths that could be returned by the lookup function.

Any of the site root directories referenced by the _sites module may, in turn, also contain a _sites module, resulting in a branching tree of sites.  When processing a request, the orginal directory is checked first.  If it contains a _sites module, its lookup function will be called.  If the directory returned by the lookup function also contains a _sites module, its lookup function will also be called.  This continues until reaching a directory thatdoes not include a _sites module.

Each directory that contains a _sites module is added to a stack of sites that are to be visited when looking for files to service a request.  This stack starts with the final, site-specific directory, goes back through each of the directories that contained a _sites module along the way and ends with the base site that is canned into Malifi at `<malifi directory>/base-site`.

If the lookup function returns its own directory, the result is the same, for that request, as if there were no _sites module in that diectory.  That directory will be at the top of the site stack.  It is an error for the lookup function not to return a directory name.

For example, when the tests are run, Malifi is initialized with `<malifi directory>/test/sites/common` as an argument.  `test/sites/common` includes a `_site.coffee` file.  When a request is received for localhost, the `lookup` method returns `<malifi directory>/test/sites/background`.  The background directory contains another `sites.coffee` file, which returns `<malifi directory>/test/sites/foreground` when when servicing a request for localhost.  The resultant site stack is:
```
<malifi directory>/test/sites/foreground
<malifi directory>/test/sites/background
<malifi directory>/test/sites/common
<malifi directory>/base-site
```

In this test environment, a request for `favicon.ico` will first be sent to the foreground site.  It is not serviced there, so it is next sent to the background site.  It then continues to the common site before finally being serviced by the base-site, where it is finally satisfied by `favicon.ico.coffee`.  Had it not been serviced by the base-site, the request would have been passed on to the next level of Connect middleware.

## Metadata

The original idea of metadata was to specify and make available information about a page or resource such as its name (perhaps needed by another resource when creating breadcrumb navigation) or whether authorization is required to access the resource.  But it soon became apparent that it could hold much more information, including configuration information for Malifi itself.  Metadata can include just about any immutable value and, depending upon where it is defined, may pertain to the entire server, a site, a directory within a site or an individual file or resource.

The metadata for any directory is specified in a `_default.meta.js` (or `_default.meta.coffee` or `_default.meta.json`) file.  Server-wide default metadata is defined in `<malifi directory>/base-site/_default.meta.coffee`.  A default value of all metadata recognized by Malifi is defined there and comments in that file describe each of those metadata properties.  Metadata properties whose name starts with an underscore are reserved for malifi and its extensions.

When Malifi is initialized, the root directory of a site to be served must be provided as the first parameter.  If an optional second parameter is provided, it will be merged with the base-site metadata so that any of the argument options override base-site metadata.  If there is a `_default.meta` module in common site's root directory (the directory provided as the first parameter), this will be merged with the result of the options merge to arrive at the server-wide metadata.

If multiple sites are defined, as each site stack is built, the `_default_meta` from the root directory of each site, if present, is similarly merged with the server-wide metadata, so that the metadata for any given site is based upon the server-wide metadata merged with any intermediate sites and the site at the top of the site stack.  In the test case, for example, the server-wide metadata is the `base-site` (Malifi default) metadata, merged with any options and then merged with the `common` site.  The `foregroud` site's metadata is the server-wide metadata merged with that of the `background` site and then with the `foreground` site.  

Each subdirectory of a site's root directory similarly inherits the root's metadata merged with any `_default.meta` module encountered in that subdirectory.  This continues for each subdirectory of a subdirectory, so that any given subdirectory inherits the metadata of the directory above it merged with any `_default.meta` module found in that subdirectory.

Finally any given resource may include a `<resource-name>.meta.js` (or .coffee or .json) module, which will be merged with the containing directory's metadata to arrive at the resource's metadata.  The resource's main module (<resource-name>.js or <resource-name>.coffee) may also export a 'meta' property which is treated the same (see test/sites/foreground/sub/addmeta.coffee for an example). If metadata is not defined for any resource (or any directory) it inherits the metadata of the directory it is contained in.  Thus every resource has associated metadata that is ultimately based upon the server-wide metadata.  This will be loaded when malifi receives a request into `req.malifi.meta`.

If the metadata module is a .js or .coffee file, it may simply export an object containing the metadata as `<malifi directory>/base-site/_default.meta.coffee` does.  It may alternatively export a function taking one parameter.  That parameter is the metadata being inherited.  It is thus possible to base the value of any given metadata object on the value it inherits or even dependant upon other metadata properties.  An example of this can be found at `<malifi directory>/test/sites/common/_default.meta.coffee`.

All metadata is preloaded in a single synchronous operation when the server is initialized.

## Actions and action handlers

When a request is received, it is sent to each site in the site stack until served.  Within each site, metadata is obtained for the requested path within the site and then that metadata is indexed by '_actions'.  That object is indexed by the requested HTTP method (HEAD is mapped to GET for this indexing operation), giving either the method object, an action handler function or an array of action handlers.

A method object is in turn indexed by either the request's extension or some other value according to the following rules:

  * If the request maps to a directory in the filesystem the method object is indexed by `'/'`.  
  * If the request includes an extension, the method object will be indexed by that extension.
  * If the request includes an extension but there is no index of the method object matching that extension, the method object will be indexed by `'*'`. 
  * If the request does not include an extension, the method object is indexed by an empty string. 
  
The result of indexing the method object is either an action handler function or an array of action handlers.

Action handlers have the same interface as Connect middleware.  They export an initialization function which returns a handler -- a function that accepts req, res and next arguments.  If the handler is able to serve the request, it sends a response to the `res` object.  If not, it calls `next()`.  If it encounters an error, it calls `next(err)`.  One additional response is allowed: the handler may call the `req.malifi.next_middleware_layer()` function, which will result in the request being immediately passed to the next Connect middleware layer, bypassing further actions in the the array of action handlers and bypassing any remaining sites.

The `next()` function in this context sends the request to the next action in the action array, or if a single action handler is specified or all actions have been visited to the next site in the site stack.  If all sites have been visited without the request being served, the request is forwarded to the next middleware layer.  

Typically an action will be looking for a file whose name matches `req.malifi.path.full_base` plus an extension, such as that of a module, as static asset or a template.  If that file exists it is served or it is called and the result served.  An action has considerable latitude in how it potentially responds to a request, and may depart from this pattern, such as performing more complex routing or redirecting the request, either internally or externally.  If the request method is other than GET or HEAD, note that the method will conventionally also be added to the expected file name as detailed in the HTTP method support section below.

## HTTP method support

If the HTTP method is something other than GET or HEAD, Malifi's convention is to append the method, converted to lower case, as an extra extension before looking for matching files.  A post to `http://example.com/a` would map to `a.post.js` or `a.post.coffee`, for example.  A common case might be that a GET of `/a` would produce a form that when filled out is POSTed to the same URL, '/a'.  These might be served by the files `a.js` (and perhaps `a.template`) and by `a.post.js` respectively.  The files would be close together in an alphabetic list of files.

Since this convention is implemented in action handlers, it can be changed by simply substituting different handlers in the metadata.

Malifi does not parse request bodies.  For POST, PUT and other methods that include a request body to work, Connect's bodyParser or equivalent middleware must preceded Malifi.

## Internal redirection (rerouting) and partials

Malifi supports internal redirection (rerouting) and partials.  Internal redirection works much like ordinary redirection but does so silently without any message exchange with the client.  A request for `/foo` ends up served by the '/bar' resource.  This might occur, for example, if the response to a given URL varies depending upon whether the user is logged in.  Internal redirects bypass the hiding rules, so that in the example above, a request for `/a` might be rerouted to `/a_logged_` if the user is logged in (because of the trailing underscore, a request for `/a_logged_` would normally be rejected as not found.  

Malifi also supports partials.  While rendering the requested resource, an internal request may be made for another resource to be inserted inside the request.  The hiding rules are also not enforced for partials.  The default Malifi implementation accumulates the result into a buffer and sends the buffer to a callback, but does not otherwise alter the result, such as by stripping HTML and BODY tags.

Rerouting is achieved by sending the destination path and optionally a hostname to `req.malifi.meta._reroute()`.  This returns an object that reroutes to that resource.  Send req,res,and next to that reroute object to actually perform the reroute.

A partial is obtained sending the destination path and optionally a hostname to `req.malifi.meta._partial()`.  This returns an object that will fetch that resource and accumulate the result.  Send req,res,next and a callback to that partial-fetching object to actually fetch the partial.  A buffer containing the result will be sent to the callback when the partial has completed.  If there is an error, including a HTTP status code other than 200 it will be sent to `next()` and the callback will never be invoked.  Any headers sent by the partial will be ignored.

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