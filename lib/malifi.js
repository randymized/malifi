
/*!
 * malifi
 * Copyright(c) 2011 Randy McLaughlin <8b629a9884@snkmail.com>
 * MIT Licensed
*/

(function() {
  var SiteStack, connect, exports, fs, join, malifi, normalize, parse, path, utils;

  fs = require('fs');

  path = require('path');

  connect = require('connect');

  utils = connect.utils;

  join = path.join;

  normalize = path.normalize;

  parse = require('url').parse;

  SiteStack = require('./siteStack');

  malifi = function(root, options) {
    var baseSiteStack, malifiMainHandler;
    if (root == null) throw new Error('malifi site root path required');
    if (options == null) options = {};
    baseSiteStack = new SiteStack(normalize(join(__dirname, root)));
    return malifiMainHandler = function(req, res, next) {
      var siteStack;
      siteStack = baseSiteStack.forHost(req);
      options.parsedURL = parse(req.url);
      options.path = decodeURIComponent(options.parsedURL.pathname);
      if (~options.path.indexOf('\0')) return next(new Error('invalid path'));
      options.fullPath = normalize(join(siteStack[0], options.path));
      if (options.fullPath.indexOf(siteStack[0]) !== 0) {
        return next(new Error('???'));
      }
      return fs.readFile(options.fullPath, function(err, data) {
        if (err) return next();
        res.setHeader('Content-Type', 'text/plain');
        return res.end(data);
      });
    };
  };

  exports = module.exports = malifi;

  exports.version = '0.0.1';

}).call(this);
