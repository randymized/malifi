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
stripExtension= require('./strip_extension')
loader= require('./loader')
action= require('./action')
package = require('../package')
readdress= require('./readdress')
extractHostAndPort= /([^:]+)(?::(.*))?/
extractNameParts= /(.*[/\\]([^/\\]+?))(\.([^.]+))?$/

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

  malifiMainHandler= (req, res, next)->
    debugger
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

    siteStack= loader.site_lookup.call(pathinfo,req).concat(baseSiteStack)
    pathparts= pathname.match(extractNameParts)

    # Add a malifi object to req.  It contains the current metadata, a
    # reference to an object that can look up any metadata, the site stack and
    # some decoded path, url and host information.
    # If malifi.alias is defined in the metadata (default is "_"), a reference
    # to the malifi object of that name will also be added to req.
    meta= loader.meta_lookup(join(siteStack[0],pathname))
    req.malifi=
      path:
        # if decoded URL ==     /zyx/abc.def.txt
        #   path.relative=      /zyx/abc.def.txt
        #   path.relative_base= /zyx/abc.def
        #   path.base=               abc.def
        #   path.dot_extension=             .txt
        #   path.extension=                  txt
        relative: pathname
        relative_base: pathparts[1]
        base: pathparts[2]
        dot_extension: pathparts[3]
        extension: pathparts[4]

        #absolute paths will be added when the site is selected from the site stack
      host: pathinfo.host
      url: pathinfo.url
      meta_lookup: loader.meta_lookup
      meta: meta
      site_stack: siteStack
      readdress: (req,res,next,url,host)->
        readdress(malifiMainHandler,req,res,next,url,host)

    req[meta._malifi_alias]= req.malifi if meta._malifi_alias

    action(req,res,next)

  return malifiMainHandler

exports = module.exports = malifi

exports.version = package.version
