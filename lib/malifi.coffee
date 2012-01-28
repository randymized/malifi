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
      req.malifi= my=
        utils: rqutils
      siteStack= baseSiteStack.getSite(req)
      my.pwd= pwd= siteStack[0]
      parsedurl= parse(req.url)
      pathname= decodeURIComponent(parsedurl.pathname)
      my.url= url=
        parsed: parsedurl
        pathname: pathname
      unless pathname.indexOf('\0')
        return utils.forbidden(res)
      fullPath= join(pwd,url.pathname)
      my.path=
        full: fullPath
        extension: path.extname(url.pathname)
        base: fullPath.replace(stripExtension,'$1')
      my.meta= {} #todo: implement the meta file loader
      # catch any use of .. to back out of the site's root directory:
      unless fullPath.indexOf(my.pwd) == 0 
        return utils.forbidden(res)
    
    # ignore non-GET requests?  TODO: check if handler exists for non-GET requests
    if req.malifi.meta.getOnly? && 'GET' != req.method && 'HEAD' != req.method
      next()
    
    #todo: presume index.html if */
    #todo: disallow outside access to _* and/or *_ files 

    staticHandler(req,res,next)
      
exports = module.exports = malifi

exports.version = '0.0.1'
