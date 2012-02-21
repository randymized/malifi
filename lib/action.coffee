connect = require('connect')
utils = connect.utils
fs = require('fs')
utilities= require('./utilities')
forbiddenURLChars = /(\/[._])|(_\/)|_$/

###
todo: // detect if URL is of a directory and, if so, bring up the _index
if (stat.isDirectory())
  if (!redirect) return @next();
  @res.statusCode = 301;
  @res.setHeader('Location', url.pathname + '/');
  @res.end('Redirecting to ' + url.pathname + '/');
  return;
}
###

exports = module.exports = action= (siteStack)->
  actions= @meta._actions

  urlExtension = @path.extension
  if urlExtension && @meta._allowed_url_extensions
    unless utilities.nameIsInArray(urlExtension,@meta._allowed_url_extensions)
      @res.statusCode = 415;
      @res.end('Unsupported Media Type');
      return;

  runActionList= (actionList)=>
    @next() unless actionList
    i= -1
    pass= ()=>
      i+= 1
      if (actionList.length > i)
        actionList[i].call(this,pass)
      else
        @next()
    pass()

  extLookup= actions[if @req.method is 'HEAD' then 'GET' else @req.method]
  extSilo = extLookup[urlExtension] ? extLookup['*']
  if extLookup['/']?
    fs.stat @path.full, (err,stats)=>
      runActionList(
        if !err && stats.isDirectory() && extLookup['$dir']?
          extLookup['$dir']
        else
          extSilo
      )
  else
    runActionList(extSilo)