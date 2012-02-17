###!
 * malifi
 * Copyright(c) 2011 Randy McLaughlin <8b629a9884@snkmail.com>
 * MIT Licensed
###

fs = require('fs')
path = require('path')
connect = require('connect')
utils = connect.utils
join = path.join
normalize = path.normalize
parse = require('url').parse
SiteStack= require('./siteStack')
RequestUtilities= require('./reqUtils')
stripExtension= /(.*)(?:\.[^/.]+)$/
Meta= require('./meta')
Action= require('./action')

malifi= (root,options)->
  unless root?
    throw new Error('malifi site root path required')
  options?= {}
  baseSiteStack= new SiteStack(normalize(root))
  meta= new Meta(baseSiteStack.stack,options)

  return malifiMainHandler= (req, res, next)->
    siteStack= null
    do ->
      rqutils= new RequestUtilities(req)
      parsedurl= parse(req.url)
      pathname= decodeURIComponent(parsedurl.pathname)
      unless pathname.indexOf('\0')
        return utils.forbidden(res)
      #Set some initial attributes of req.malifi.  More will be added after baseSiteStack.getSite() is invoked, but
      #methods that it invokes may expect req.malifi to have as many attributes set as possible without knowing what
      #the current site's directory is (which is what getSite() establishes).
      req.malifi= my=
        utils: rqutils
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

    new Action(req,res,next)

exports = module.exports = malifi

exports.version = '0.0.1'
