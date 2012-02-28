connect = require('connect')
forbidden = connect.utils.forbidden
fs = require('fs')
path = require('path')
join = path.join
utilities= require('./utilities')

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

exports = module.exports = action= ()->
  @meta._unhandled_handler?.log?.call(this)

  if @meta._forbiddenURLChars?.test(@url.decoded_path)
    return forbidden(@res)

  urlExtension = @path.extension
  if urlExtension && @meta._allowed_url_extensions
    unless utilities.nameIsInArray(urlExtension,@meta._allowed_url_extensions)
      return @next()

  actions= @meta._actions
  extLookup= actions[if @req.method is 'HEAD' then 'GET' else @req.method]
  extSilo = extLookup[urlExtension] ? extLookup['*']

  siteindex= 0
  nextSite= ()=>
    root= @site_stack[siteindex++]
    unless root
      @next()
    else
      traverseActionList = (actionList)=>
        nextSite() unless actionList
        i= 0
        pass = ()=>
          try
            actor= actionList[i++]
            if (actor)
              actor.call(this,pass)
            else
              nextSite()
          catch e
            @next(e)
        pass()

      pathobj= @path
      pathobj.site_root= root
      pathobj.full= join(root,@path.relative)
      pathobj.full_base= join(root,@path.relative_base)

      if extLookup['/']?
        fs.stat @path.full, (err,stats)=>
          if !err && stats.isDirectory() && extLookup['/']?
            traverseActionList(extLookup['/'])
          else
            traverseActionList(extSilo)
      else
        traverseActionList(extSilo)
  nextSite()