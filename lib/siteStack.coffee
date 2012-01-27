connect = require('connect')
fs = require('fs')
path = require('path')
join = path.join
normalize = path.normalize
placeholder= /@@/
extractHostFromHost= /([^:]+).*/
extractPortFromHost= /[^:]+:(.*)/

module.exports = exports= class SiteStack
  constructor: (defaultSiteDir)->
    @stack=[defaultSiteDir, normalize(join(__dirname,'../default-site'))]
    sitesFileName= join(defaultSiteDir,'sites.js')
    @sitemap= null
    try
      stat= fs.statSync(sitesFileName)
    catch e
      if e.code == 'ENOENT' then return null
      else throw e
    @sitelookup= require(sitesFileName).bind(process)
      
  doLookup: (req)->
    environment= process.env
    argv= process.argv
    headers= req.headers
    host= req.headers.host
    hostname= req.headers.host.replace(extractHostFromHost,'$1')
    port= req.headers.host.replace(extractPortFromHost,'$1')
    @sitelookup()      

  forHost: (req) ->
    siteStack= connect.utils.toArray @stack
    if @sitelookup? && (hostSite= @sitelookup(req))
      siteStack.unshift(normalize(join(@stack[0],hostSite)))
    siteStack
        
exports.loadScriptSync= loadScriptSync= (name,wrapper)->
  try
    body= wrapper.replace(placeholder,fs.readFileSync(name, 'utf8'))
  catch e
    if e.code == 'ENOENT'
        return null
    throw e
  try
    f= new Function(body)
    f=f()
  catch e
    if e == "SyntaxError"
      throw new SyntaxError("\"#{e.message}\" in #{name}")
    else
      throw e
  return f

