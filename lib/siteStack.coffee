connect = require('connect')
fs = require('fs')
path = require('path')
join = path.join
normalize = path.normalize

module.exports = exports= class SiteStack
  constructor: (defaultSiteDir)->
    @stack=[normalize(defaultSiteDir), normalize(join(__dirname,'../default-site'))]
    sitesFileName= join(defaultSiteDir,'sites.js')
    @sitemap= null
    try
      stat= fs.statSync(sitesFileName)
    catch e
      if e.code == 'ENOENT' then return null
      else throw e
    @sitelookup= require(sitesFileName).bind(process)
      
  getSite: (req) ->
    siteStack= connect.utils.toArray @stack
    if @sitelookup? && (hostSite= @sitelookup(req))
      siteStack.unshift(normalize(join(@stack[0],hostSite)))
    siteStack
