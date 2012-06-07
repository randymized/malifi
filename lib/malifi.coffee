###!
 * malifi
 * Copyright(c) 2011 Randy McLaughlin <8b629a9884@snkmail.com>
 * MIT Licensed
###

fs = require('fs')
path = require('path')
join = path.join
normalize = path.normalize
forbidden = require('./forbidden')
parse = require('url').parse
loader= require('./loader')
find_files= require('./find_files')
package = require('../package')
dummy_router= require('./action_handlers/dummy_router')('')
extractHostAndPort= /([^:]+)(?::(.*))?/
extractNameParts= /(?:((.*)\/([^/]*))\/$)|((.*)\/([^/]+?))(\.([^./]+))?$/

class ParseHost
  constructor: (req)->
    matches = req.headers.host.match(extractHostAndPort);
    @name= matches[1]
    @port= matches[2]

malifi= (root,options)->
  unless root?
    throw new Error('malifi site root path required')
  options?= {}
  baseSiteStack= [normalize(root), normalize(join(__dirname,'../base-site'))]
  loader.init(baseSiteStack,options)

  malifiConnectHandler= (req, res, next)->
    parsedurl= parse(req.url,true)
    pathname= decodeURIComponent(parsedurl.pathname)
    unless pathname.indexOf('\0')
      return forbidden(res)
    pathinfo=
      host: new ParseHost(req)
      url:
        raw: req.url
        parsed: parsedurl
        decoded_path: pathname

    try
      siteStack= loader.site_lookup.call(pathinfo,req,res,next).concat(baseSiteStack)
    catch e
      return next(new Error('Unknown site'))
    pathparts= pathname.match(extractNameParts) || []

    # Add a malifi object to req.  It contains the current metadata, a
    # reference to an object that can look up any metadata, the site stack and
    # some decoded path, url and host information.
    # If malifi.alias is defined in the metadata (default is "_"), a reference
    # to the malifi object of that name will also be added to req.
    meta= loader.meta_lookup(pathname,loader.calc_site_key(siteStack),true)
    basename= (pathparts[6] || '')+(pathparts[7] || '')
    req.malifi= malifi=
      path:
        if pathparts[1]
          # if decoded URL ==               # /zyx/abc/
          relative:      pathparts[1] ? '/' # /zyx/abc
          relative_base: pathparts[1] ? '/' # /zyx/abc
          dirname:       pathparts[2] ? '/' # /zyx
          base:          pathparts[3] ? ''  #      abc
          basename:      pathparts[3] ? ''  #      abc
          dot_extension: ''                 # (empty string)
          extension: '/'                    # /
        else
          # if decoded URL ==               # /zyx/abc.def.txt
          relative: pathname                # /zyx/abc.def.txt
          relative_base: pathparts[4] ? '/' # /zyx/abc.def
          dirname: pathparts[5] ? '/'       # /zyx
          base: pathparts[6] ? ''           #      abc.def
          basename: basename                #      abc.def.txt
          dot_extension: pathparts[7] ? ''  #             .txt
          extension: pathparts[8] ? ''      #              txt
      host: pathinfo.host
      url: pathinfo.url
      meta: meta
      site_stack: siteStack
      connect_handler: malifiConnectHandler
      find_files: find_files
      next_middleware_layer: next

    req[meta.malifi_alias_]= req.malifi if meta.malifi_alias_

    if meta.custom_404_ || meta.custom_500_
      orignext= next
      next= (err)->
        nonext= (err)->   # this should never be called: _500 or _404 should not call next()
          throw "No _505 or _404 handler found or the handler punted."
        if err?
          if meta.custom_500_
            req.err= err
            meta.reroute_('/_500')(req,res,nonext)
          else
            orignext(err)
        else
          if meta.custom_404_
            req.notfound= req.malifi.url.decoded_path
            meta.reroute_('/_404')(req,res,nonext)
          else
            orignext()

    meta.unhandled_handler_?.log?(req)

    (meta.rerouter_ || dummy_router) req,res,(err)->
      return next(err) if err
      if actions = meta.actions_
        actions(req,res,next)
      else
        next(new Error('meta.actions_ is not defined.'))

  return malifiConnectHandler

exports = module.exports = malifi

exports.version = package.version

# export lib modules
fs.readdirSync(__dirname).forEach (filename)->
  if (/\.(js|coffee)$/.test(filename))
    name = filename.substr(0, filename.lastIndexOf('.'))
    exports.__defineGetter__ name, ()->
      require('./' + name)

# export action handlers
exports.action_handlers= action_handlers= {}
fs.readdirSync(__dirname+'/action_handlers').forEach (filename)->
  if (/\.(js|coffee)$/.test(filename))
    name = filename.substr(0, filename.lastIndexOf('.'))
    action_handlers.__defineGetter__ name, ()->
      require('./action_handlers/' + name)
