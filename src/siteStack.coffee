connect = require('connect')
path = require('path')
join = path.join
normalize = path.normalize

stripPortFromHost= /([^:]+).*/
module.exports = exports= class SiteStack
    constructor: (defaultSiteDir)->
        @stack=[defaultSiteDir, normalize(join(__dirname,'../default-site'))]
        sitesFileName= join(defaultSiteDir,'sites.js')
        @sitemap= null
        try
            @sitemap= loadScriptWithImpliedReturnSync(sitesFileName)
        catch err

    forHost: (req) ->
        siteStack= connect.utils.toArray @stack
        if @sitemap? && (hostSite= @sitemap[req.headers.host.replace(stripPortFromHost,'$1')])
            siteStack.unshift(normalize(join(siteStack[0],hostSite)))
        siteStack
