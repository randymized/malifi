connect = require('connect')
utils = connect.utils
fs = require('fs')
path = require('path')
join = path.join
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

exports = module.exports = action= ()->
  @meta._unhandled_handler?.log?.call(this)

  urlExtension = @path.extension
  if urlExtension && @meta._allowed_url_extensions
    unless utilities.nameIsInArray(urlExtension,@meta._allowed_url_extensions)
      @res.statusCode = 415;
      @res.end('Unsupported Media Type');
      return;

  @meta_lookup('/x')
  actions= @meta._actions
  extLookup= actions[if @req.method is 'HEAD' then 'GET' else @req.method]
  extSilo = extLookup[urlExtension] ? extLookup['*']

  siteindex= 0
  nextSite= ()=>
    if (root= @site_stack[siteindex++])
      pathobj= @path
      pathobj.site_root= root
      pathobj.full= join(root,@path.relative)
      pathobj.base= join(root,@path.relative_base)

      traverseActionList= (actionList)=>
        @next() unless actionList
        i= 0
        pass= ()=>
          try
            actor= actionList[i++]
            if (actor)
              actor.call(this,pass)
            else
              nextSite()
          catch e
            @next(e)
        pass()

      if extLookup['/']?
        fs.stat @path.full, (err,stats)=>
          if !err && stats.isDirectory() && extLookup['/']?
            traverseActionList(extLookup['/'])
          else
            traverseActionList(extSilo)
      else
        traverseActionList(extSilo)

    else
      @next()
  nextSite()