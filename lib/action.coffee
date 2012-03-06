connect = require('connect')
forbidden = connect.utils.forbidden
fs = require('fs')
path = require('path')
join = path.join
utilities= require('./utilities')

###
todo: // detect if URL is of a directory and, if so, bring up the _index
if (stat.isDirectory())
  if (!redirect) return next();
  res.statusCode = 301;
  res.setHeader('Location', url.pathname + '/');
  res.end('Redirecting to ' + url.pathname + '/');
  return;
}
###

exports = module.exports = action= (req,res,next)->
  malifi= req.malifi
  meta= malifi.meta
  pathobj= malifi.path
  meta._unhandled_handler?.log?(req)

  if meta._forbiddenURLChars?.test(malifi.url.decoded_path)
    return forbidden(res)

  urlExtension = pathobj.extension
  if urlExtension && meta._allowed_url_extensions
    unless utilities.nameIsInArray(urlExtension,meta._allowed_url_extensions)
      return next()

  actions= meta._actions
  extLookup= actions[if req.method is 'HEAD' then 'GET' else req.method]
  extSilo = extLookup[urlExtension] ? extLookup['*']

  malifi.next_layer= next_layer= next
  siteindex= 0
  nextSite= ()=>
    root= malifi.site_stack[siteindex++]
    unless root
      next_layer()
    else
      traverseActionList = (actionList)=>
        nextSite() unless actionList
        i= 0
        next= (err)=>
          next_layer(err) if err
          try
            actor= actionList[i++]
            if (actor)
              actor(req,res,next)
            else
              nextSite()
          catch e
            next_layer(e)
        next()

      pathobj.site_root= root
      pathobj.full= join(root,pathobj.relative)
      pathobj.full_base= join(root,pathobj.relative_base)

      if extLookup['/']?
        fs.stat pathobj.full, (err,stats)=>
          if !err && stats.isDirectory() && extLookup['/']?
            traverseActionList(extLookup['/'])
          else
            traverseActionList(extSilo)
      else
        traverseActionList(extSilo)
  nextSite()