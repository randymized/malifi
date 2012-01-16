
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
  
exports.version = '0.0.1';

exports = module.exports = function malifi(root, options){
  options = options || {}

  // root required
  if (!root) throw new Error('malifi site root path required');
  options.root = normalize(join(__dirname,root));

  return function malifiMainHandler(req, res, next) {
    options.parsedURL= parse(req.url)
    options.path = decodeURIComponent(options.parsedURL.pathname);
    if (~options.path.indexOf('\0')) return next(utils.error(400));
    options.fullPath = normalize(join(options.root,options.path));
    // catch any use of .. to back out of the site's root directory:
    if (options.fullPath.indexOf(options.root) != 0) return next(utils.error(400));
    
    fs.readFile(options.fullPath, function (err, data) {
      if (err) {
        debugger
        return 'ENOENT' == err.code
          ? next()
          : next(err);
      }
      res.setHeader('Content-Type', 'text/plain');
      res.end(data);
    })
  }
}