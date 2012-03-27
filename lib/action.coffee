_ = require('underscore')._
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

  find_files= (dirname, basename, cb)->
    dirname= '' if '/' == dirname
    re= new RegExp("^#{basename}(?:\\.(.+))?$")
    completed= 0
    findings= {}
    site_stack = malifi.site_stack.reverse()
    loops = site_stack.length
    oneDone= ()->
      if loops == ++completed
        # all readdir results have been received and added to findings
        candidates= {}
        for site in malifi.site_stack # merge, priortizing most specific site
          _.extend(candidates,findings[site])
        for ext,name of candidates
          candidates[ext]= name+'.'+ext if ext && '/' != ext
        cb(candidates)
    for site in site_stack
      do ()->
        sitedir= site
        searchpath= join(sitedir,dirname)
        fs.readdir searchpath, (err,files)->
          if files
            for file in files
              m= re.exec(file)
              (findings[sitedir] ?= {})[m[1] ? ''] = join(searchpath,basename) if m
          finding = findings[sitedir]
          if finding?['']
            fs.stat finding[''], (err,stats)->
              if stats.isDirectory()
                finding['/']= finding['']
                delete finding['']
              oneDone()
          else
            oneDone()

  find_files pathobj.dirname, pathobj.basename, (files)->
    if files['/'] && meta._indexResourceName && 1 == Object.keys(files).length
      # A directory was found.  Scan it, looking for _index files
      find_files join(pathobj.dirname,pathobj.basename), meta._indexResourceName, (indexFiles)->
        selectActions(_.extend(files,indexFiles))
    else
      selectActions(files)
