_ = require('underscore')._
path = require('path')
join = path.join
utilities= require('./utilities')
find_files= require('./find_files')
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

    if urlExtension && meta._allowed_url_extensions && '/' != urlExtension
      unless utilities.nameIsInArray(urlExtension,meta._allowed_url_extensions)
        return next()

  selectActions= (files)->
    debugger
    malifi.files= files
    malifi.next_middleware_layer= next
    traverseActionList = (silo,nextActionList)=>
      return next() unless silo
      if _.isFunction(silo)
        silo= [silo]
      i= 0
      nextActionHandler= (err)=>
        next(err) if err
        try
          actor= silo[i++]
          if (actor)
            actor(req,res,nextActionHandler)
          else
            next()
        catch e
          next(e)
      nextActionHandler()

    extLookup= meta._actions[if req.method is 'HEAD' then 'GET' else req.method]
    return next() unless extLookup?

    if _.isArray(extLookup) ||_.isFunction(extLookup)
      traverseActionList(extLookup)
    else
      if pathobj.extension == ['/']
        traverseActionList(extLookup['/'])
      else
        traverseActionList(extLookup[urlExtension] ? extLookup['*'])

  find_files.call malifi, pathobj.dirname, pathobj.basename, (files)->
    if files['/'] && meta._indexResourceName && 1 == Object.keys(files).length
      # A directory was found.  Scan it, looking for _index files
      find_files.call malifi, join(pathobj.dirname,pathobj.basename), meta._indexResourceName, (indexFiles)->
        selectActions(_.extend(files,indexFiles))
    else
      selectActions(files)
