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
staticHandler= require('./staticHandler')
stripExtension= /(.*)(?:\.[^/.]+)$/

malifi= (root,options)->
  unless root?
    throw new Error('malifi site root path required')
  options?= {}
  debugger
  baseSiteStack= new SiteStack(normalize(join(__dirname,root)))
  
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
      my.meta= {} #todo: implement the meta file loader

    my= req.malifi

    # catch any use of .. to back out of the site's root directory:
    unless 0 == my.path.full.indexOf(my.pwd)
      return utils.forbidden(res)
    
    # ignore non-GET requests?  TODO: check if handler exists for non-GET requests
    if my.meta.getOnly? && 'GET' != req.method && 'HEAD' != req.method
      next()
    
    #todo: presume index.html if */
    #todo: disallow outside access to _* and/or *_ files 

    staticHandler(req,res,next)
      
exports = module.exports = malifi

exports.version = '0.0.1'
