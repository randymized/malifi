(function() {
  var SiteStack, connect, exports, extractHostFromHost, extractPortFromHost, fs, join, loadScriptSync, normalize, path, placeholder;

  connect = require('connect');

  fs = require('fs');

  path = require('path');

  join = path.join;

  normalize = path.normalize;

  placeholder = /@@/;

  extractHostFromHost = /([^:]+).*/;

  extractPortFromHost = /[^:]+:(.*)/;

  module.exports = exports = SiteStack = (function() {

    function SiteStack(defaultSiteDir) {
      var sitesFileName, stat;
      this.stack = [defaultSiteDir, normalize(join(__dirname, '../default-site'))];
      sitesFileName = join(defaultSiteDir, 'sites.js');
      this.sitemap = null;
      try {
        stat = fs.statSync(sitesFileName);
      } catch (e) {
        if (e.code === 'ENOENT') {
          return null;
        } else {
          throw e;
        }
      }
      this.sitelookup = require(sitesFileName).bind(process);
    }

    SiteStack.prototype.doLookup = function(req) {
      var argv, environment, headers, host, hostname, port;
      environment = process.env;
      argv = process.argv;
      headers = req.headers;
      host = req.headers.host;
      hostname = req.headers.host.replace(extractHostFromHost, '$1');
      port = req.headers.host.replace(extractPortFromHost, '$1');
      return this.sitelookup();
    };

    SiteStack.prototype.forHost = function(req) {
      var hostSite, siteStack;
      siteStack = connect.utils.toArray(this.stack);
      if ((this.sitelookup != null) && (hostSite = this.sitelookup(req))) {
        siteStack.unshift(normalize(join(this.stack[0], hostSite)));
      }
      return siteStack;
    };

    return SiteStack;

  })();

  exports.loadScriptSync = loadScriptSync = function(name, wrapper) {
    var body, f;
    try {
      body = wrapper.replace(placeholder, fs.readFileSync(name, 'utf8'));
    } catch (e) {
      if (e.code === 'ENOENT') return null;
      throw e;
    }
    try {
      f = new Function(body);
      f = f();
    } catch (e) {
      if (e === "SyntaxError") {
        throw new SyntaxError("\"" + e.message + "\" in " + name);
      } else {
        throw e;
      }
    }
    return f;
  };

}).call(this);
