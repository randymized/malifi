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

malifi= (root,options)->
  unless root?
    throw new Error('malifi site root path required')
  options?= {}
  baseSiteStack= new SiteStack(normalize(join(__dirname,root)))
  
  return malifiMainHandler= (req, res, next)->
    siteStack= baseSiteStack.forHost(req)
    options.parsedURL= parse(req.url)
    options.path = decodeURIComponent(options.parsedURL.pathname)
    if ~options.path.indexOf('\0')
      return next(new Error('invalid path'))
    options.fullPath= normalize(join(siteStack[0],options.path))
    # catch any use of .. to back out of the site's root directory:
    unless options.fullPath.indexOf(siteStack[0]) == 0 
        return next(new Error('???'))
    
    fs.readFile options.fullPath, (err,data)->
      if err
        return next()
      res.setHeader 'Content-Type', 'text/plain'
      res.end(data)
      
exports = module.exports = malifi

exports.version = '0.0.1'
