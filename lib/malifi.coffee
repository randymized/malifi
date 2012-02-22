###!
 * malifi
 * Copyright(c) 2011 Randy McLaughlin <8b629a9884@snkmail.com>
 * MIT Licensed
###

path = require('path')
connect = require('connect')
forbidden = connect.utils.forbidden
join = path.join
normalize = path.normalize
parse = require('url').parse
SiteStack= require('./site_stack')
stripExtension= require('./strip_extension')
Meta= require('./meta')
action= require('./action')
extractHostAndPort= /([^:]+)(?::(.*))?/

class ParseHost
  constructor: (req)->
    matches = req.headers.host.match(extractHostAndPort);
    @name= matches[1]
    @port= matches[2]

malifi= (root,options)->
  unless root?
    throw new Error('malifi site root path required')
  options?= {}
  baseSiteStack= new SiteStack(normalize(root))
  meta= new Meta(baseSiteStack,options)

  return malifiMainHandler= (req, res, next)->
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
    siteStack= baseSiteStack.getSite(req,pathinfo)

    # Actions and page modules are run in the scope of actionobj.
    # It provides access to req, res, next as well as pathinfo and the metadata
    # for the URL being served.  It can also be used as a bus for conveying
    # other data among action and page modules.
    # Actionobj is unique and specific to one request and its lifetime is
    # that of the request.
    actionobj=
      req: req
      res: res
      next: next
      path:
        relative: pathname
        extension: path.extname(pathname)
        relative_base: base= stripExtension(pathname)
        #absolute paths will be added when the site is selected from the site stack
      host: pathinfo.host
      url: pathinfo.url
      meta_lookup: meta.find
      meta: meta.find(join(siteStack[0],pathname))
      site_stack: siteStack

    action.call(actionobj)

exports = module.exports = malifi

exports.version = '0.0.1'
