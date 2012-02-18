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
stripExtension= /(.*)(?:\.[^/.]+)$/
Meta= require('./meta')
action= require('./action')
extractHostFromHost= /([^:]+).*/
extractPortFromHost= /[^:]+:(.*)/

class ParseHost
  constructor: (req)->
    @host= req.headers.host
  hostname: -> @_hostname||= @host.replace(extractHostFromHost,'$1')
  port: -> @_port||= @host.replace(extractPortFromHost,'$1')

malifi= (root,options)->
  unless root?
    throw new Error('malifi site root path required')
  options?= {}
  baseSiteStack= new SiteStack(normalize(root))
  meta= new Meta(baseSiteStack,options)

  return malifiMainHandler= (req, res, next)->
    siteStack= null
    parsedurl= parse(req.url)
    pathname= decodeURIComponent(parsedurl.pathname)
    unless pathname.indexOf('\0')
      return forbidden(res)
    #Set some initial attributes of req.malifi.  More will be added after baseSiteStack.getSite() is invoked, but
    #methods that it invokes may expect req.malifi to have as many attributes set as possible without knowing what
    #the current site's directory is (which is what getSite() establishes).
    pathinfo=
      host: new ParseHost(req)
      url:
        parsed: parsedurl
        pathname: pathname
    siteStack= baseSiteStack.getSite(req,pathinfo)
    #Now that we know the current site's directory, fill in the rest of the attributes
    pathinfo.pwd= siteStack[0]
    fullPath= join(pathinfo.pwd,pathname)
    pathinfo.path=
      full: fullPath
      extension: path.extname(pathinfo.url.pathname)
      base: fullPath.replace(stripExtension,'$1')

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
      pathinfo: pathinfo
      meta: meta.default #todo: implement the meta file loader
    action.call(actionobj,action.defaultActions)

exports = module.exports = malifi

exports.version = '0.0.1'
