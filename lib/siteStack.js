(function() {
  var SiteStack, connect, exports, join, normalize, path, stripPortFromHost;

  connect = require('connect');

  path = require('path');

  join = path.join;

  normalize = path.normalize;

  stripPortFromHost = /([^:]+).*/;

  module.exports = exports = SiteStack = (function() {

    function SiteStack(defaultSiteDir) {
      var sitesFileName;
      this.stack = [defaultSiteDir, normalize(join(__dirname, '../default-site'))];
      sitesFileName = join(defaultSiteDir, 'sites.js');
      this.sitemap = null;
      try {
        this.sitemap = loadScriptWithImpliedReturnSync(sitesFileName);
      } catch (err) {

      }
    }

    SiteStack.prototype.forHost = function(req) {
      var hostSite, siteStack;
      siteStack = connect.utils.toArray(this.stack);
      if ((this.sitemap != null) && (hostSite = this.sitemap[req.headers.host.replace(stripPortFromHost, '$1')])) {
        siteStack.unshift(normalize(join(siteStack[0], hostSite)));
      }
      return siteStack;
    };

    return SiteStack;

  })();

}).call(this);
