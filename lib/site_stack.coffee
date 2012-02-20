connect = require('connect')
fs = require('fs')
path = require('path')
join = path.join
normalize = path.normalize
utilities= require('./utilities')
isModuleSync= utilities.isModuleSync

module.exports = exports= class SiteStack
  constructor: (defaultSiteDir)->
    @stack=[normalize(defaultSiteDir), normalize(join(__dirname,'../base-site'))]
    sitesFileName= join(defaultSiteDir,'_sites')
    @sitemap= null
    debugger
    return null unless isModuleSync(sitesFileName)
    @siteMapper= require(sitesFileName)
      
  getSite: (req,pathinfo) ->
    siteStack= @stack
    if @siteMapper? && (hostSite= @siteMapper.lookup.call(pathinfo,req))
      siteStack.unshift(normalize(hostSite))
    siteStack
