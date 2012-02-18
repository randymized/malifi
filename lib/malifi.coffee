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
  hostname: -> @qhostname||= @host.replace(extractHostFromHost,'$1')
  port: -> @qport||= @host.replace(extractPortFromHost,'$1')

malifi= (root,options)->
  unless root?
    throw new Error('malifi site root path required')
  options?= {}
  baseSiteStack= new SiteStack(normalize(root))
  meta= new Meta(baseSiteStack,options)

  return malifiMainHandler= (req, res, next)->
    siteStack= null
    do ->
      parsedurl= parse(req.url)
      pathname= decodeURIComponent(parsedurl.pathname)
      unless pathname.indexOf('\0')
        return forbidden(res)
      #Set some initial attributes of req.malifi.  More will be added after baseSiteStack.getSite() is invoked, but
      #methods that it invokes may expect req.malifi to have as many attributes set as possible without knowing what
      #the current site's directory is (which is what getSite() establishes).
      req.malifi= my=
        host: new ParseHost(req)
        url:
          parsed: parsedurl
          pathname: pathname
      siteStack= baseSiteStack.getSite(req)
      #Now that we know the current site's directory, fill in the rest of the attributes
      my.pwd= siteStack[0]
      fullPath= join(my.pwd,pathname)
      my.path=
        full: fullPath
        extension: path.extname(my.url.pathname)
        base: fullPath.replace(stripExtension,'$1')
      my.meta= meta.default #todo: implement the meta file loader

    action(action.defaultActions,req,res,next)

exports = module.exports = malifi

exports.version = '0.0.1'
