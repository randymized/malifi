connect = require('connect')
utils = connect.utils
forbiddenURLChars= /\/([._][^/]*)|_$/

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

  if forbiddenURLChars.test(@pathinfo.url.pathname)
    @res.statusCode = 403;
    @res.end('Forbidden URL');
    return;

  urlExtension = @pathinfo.path.extension
  if urlExtension && @meta._allowed_url_extensions
    aue= @meta._allowed_url_extensions
    aue.regexp ?= new RegExp('((\.' + aue.join(')|(\.') + '))$')
    unless aue.regexp.test(urlExtension)
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