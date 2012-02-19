connect = require('connect')
utils = connect.utils


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
  actions= @meta._actions

  urlExtension = @pathinfo.path.extension
  if urlExtension
    aue= @meta._allowed_url_extensions
    unless aue.set
      s= {}
      s['.'+key]=true for key in aue
      aue.set= s
    unless aue.set[urlExtension]
      @res.statusCode = 415;
      @res.end('Unsupported Media Type');
      return;

  actionList= actions[urlExtension] ? actions['*']
  @next() unless actionList
  i= -1
  pass= ()=>
    i+= 1
    if (actionList.length > i)
      actionList[i].call(this,pass)
    else
      @next()
  pass()