_ = require('underscore')._
connect = require('connect')
fs = require('fs')
path = require('path')
join = path.join
utilities= require('./utilities')
forbidden = utilities.forbidden

exports = module.exports = action= (req,res,next)->
  malifi= req.malifi
  meta= malifi.meta
  pathobj= malifi.path
  meta._unhandled_handler?.log?(req)
  urlExtension = pathobj.extension

  unless req.internal?  # internal requests and redirections may address resources that are hidden to the outside world
    if meta._forbiddenURLChars?.test(malifi.url.decoded_path)
      return forbidden(res)

    if urlExtension && meta._allowed_url_extensions
      unless utilities.nameIsInArray(urlExtension,meta._allowed_url_extensions)
        return next()

  malifi.next_layer= next_layer= next
  siteindex= 0
  nextSite= ()=>
    root= malifi.site_stack[siteindex++]
    unless root
      next_layer()
    else
      traverseActionList = (silo)=>
        return nextSite() unless silo
        if _.isFunction(silo)
          silo= [silo]
        i= 0
        next= (err)=>
          next_layer(err) if err
          try
            actor= silo[i++]
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

      site_meta= malifi.site_meta= malifi.meta_lookup(join(root,malifi.path.relative))
      actions= site_meta._actions
      extLookup= actions[if req.method is 'HEAD' then 'GET' else req.method]
      return nextSite() unless extLookup?

      if _.isArray(extLookup) ||_.isFunction(extLookup)
        traverseActionList(extLookup)
      else
        fs.stat pathobj.full, (err,stats)=>
          if !err && stats.isDirectory()
            traverseActionList(extLookup['/'])
          else
            traverseActionList(extLookup[urlExtension] ? extLookup['*'])
  nextSite()