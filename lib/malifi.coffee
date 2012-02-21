###!
 * malifi
 * Copyright(c) 2011 Randy McLaughlin <8b629a9884@snkmail.com>
 * MIT Licensed
###

fs = require('fs')
path = require('path')
connect = require('connect')
forbidden = connect.utils.forbidden
join = path.join
normalize = path.normalize
parse = require('url').parse
SiteStack= require('./site_stack')
stripExtension= require('./strip_extension')
unhandledHandler= require('./unhandled_exception_handler')
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

    pwd= siteStack[0]
    fullPath= join(pwd,pathname)
    base= stripExtension(fullPath)

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
        site_root: pwd
        full: fullPath
        relative: fullPath.substr(pwd.length)
        extension: path.extname(fullPath)
        base: base
        relative_base: base.substr(pwd.length)
      host: pathinfo.host
      url: pathinfo.url
      meta: meta.find(fullPath)

    if actionobj.meta._forbiddenURLChars?.test(pathname)
      return forbidden(res)
    unhandledHandler.log.call(actionobj)
    action.call(actionobj,siteStack)

exports = module.exports = malifi

exports.version = '0.0.1'
