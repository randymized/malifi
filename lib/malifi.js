/*!
 * malifi
 * Copyright(c) 2011 Randy McLaughlin <8b629a9884@snkmail.com>
 * MIT Licensed
 */

var fs = require('fs')
  , path = require('path')
  , connect = require('connect')
  , utils = connect.utils
  , join = path.join
  , basename = path.basename
  , normalize = path.normalize
  , parse = require('url').parse
  ;

exports = module.exports = malifi;

exports.version = '0.0.1';

var pfxWithReturnRegex= /(?:\s+return\s+)?(.*)&/
exports.prefixWithReturn= prefixWithReturn= function(s) {
  return s.replace(pfxWithReturnRegex,'replace $1')
}

exports.loadScriptWithImpliedReturnSync= loadScriptWithImpliedReturnSync= function(name){
  return new Function(prefixWithReturn(fs.readFileSync(name, 'utf8')))()
}

function SiteStack(defaultSiteDir)
{
  var stripPortFromHost= /([^:]+).*/
    , stack=[defaultSiteDir, normalize(join(__dirname,'../default-site'))]
    , sitesFileName= join(defaultSiteDir,'sites.js')
    , sitemap

  // If a sites.js file is found in the specified root directory, it maps hostnames to directory trees.
  try {
    sitemap= loadScriptWithImpliedReturnSync(sitesFileName)
  }
  catch (er) {} 

  // gets the site stack for the hostname found in req
  this.forHost= function(req) {
    var siteStack= utils.toArray(stack)
    if (sitemap) {
      var hostSite= sitemap[req.headers.host.replace(stripPortFromHost,'$1')]
      if (hostSite) {
        siteStack.unshift(normalize(join(siteStack[0],hostSite))) 
      }
    }
    return siteStack
  }
}

function malifi(root,options){
  if (!root) throw new Error('malifi site root path required');
  options = options || {}
  var baseSiteStack= new SiteStack(normalize(join(__dirname,root)))
    
  

  return function malifiMainHandler(req, res, next) {
    var siteStack= baseSiteStack.forHost(req)
    options.parsedURL= parse(req.url)
    options.path = decodeURIComponent(options.parsedURL.pathname);
    if (~options.path.indexOf('\0')) return next(utils.error(400));
    options.fullPath = normalize(join(siteStack[0],options.path));
    // catch any use of .. to back out of the site's root directory:
    if (options.fullPath.indexOf(siteStack[0]) != 0) return next(utils.error(400));
    
    fs.readFile(options.fullPath, function (err, data) {
      if (err) {
        return 'ENOENT' == err.code
          ? next()
          : next(err);
      }
      res.setHeader('Content-Type', 'text/plain');
      res.end(data);
    })
  }
}