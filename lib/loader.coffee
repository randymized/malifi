_ = require('underscore')._
connect = require('connect')
path = require('path')
normalize = path.normalize
path = require('path')
normalize = path.normalize
fs = require('fs')
stripExtension= require('./strip_extension')
metafileSignature= /\.meta\.(js|coffee|json)$/
moduleSignature= /\.(js|coffee|json)$/
skipThisFileSignature= /^\.|^_default\.meta\.(js|coffee|json)$/
stripMetaExtension= /(.*)(?:\.meta\.(js|coffee|json))$/
moduleExtensions= ['.js','.coffee','.json']


isFileSync= (name)->
  try
    fs.statSync(name).isFile()
  catch e
    throw e unless e.code == 'ENOENT'
    false

# Would adding the proper extension to the given name find a file whose extension
# suggested that it could be a module?
isModuleSync= (name)->
  return true for ext in moduleExtensions when isFileSync(name+ext)
  false

extend= (base,dominant,name)->
  return dominant unless base
  # A meta file module may be a function or an object.  If its a function,
  # it will be invoked with the parent metadata as an argument and should return
  # a metadata object.  The meta file can thus create metadata that is
  # affected by the values in the parent metadata
  dominant= dominant(_.clone(base)) if typeof dominant == "function"
  r= _.clone(base)
  for key,val of dominant
    if val?
      r[key]=val
    else
      delete r[key]
  if r['build_lineage_']
    (r['lineage_']= ((base['lineage_']||[])).slice(0)).push(name)
  r

cache= {}

meta_lookup= (name,from)->
  from||= cache
  descend= (name)->
    if from[name]
      return from[name]
    else
      lower= path.dirname(name)
      return {} if lower == name  # emergency shut-off: already at root directory
      return meta_lookup(lower+'/')
  if c= from[name+'/']  # the original file name is that of a directory and it has default metadata
    return c
  descend(name)

load= (name,superMeta)->
  extend(superMeta, require(name), name)

loadTree= (rootdir,superMeta,supersites) ->
  modules= []
  loadDir= (dirname,superMeta,visited) ->   #recursive
    defaultModName = path.join(dirname,'_default.meta')
    meta= if isModuleSync(defaultModName)
      cache[dirname+'/']= load(defaultModName,superMeta)
    else
      superMeta
    for filename in fs.readdirSync(dirname)
      unless skipThisFileSignature.test(filename)
        filename= path.join(dirname,filename)
        stat = fs.lstatSync(filename)
        if stat.isDirectory()
          unless visited[stat.ino]  # do not follow circular symbolic link
            newvisited= {}
            newvisited[ino] = true for ino, val of visited
            newvisited[stat.ino]= true
            loadDir(filename,meta,newvisited)
        else
          if moduleSignature.test(filename)
            stripped= stripExtension(filename)
            if metafileSignature.test(filename)
              cache[filename.replace(stripMetaExtension,'$1')]= load(stripped,meta)
            else
              modules.unshift(stripped)
    return meta
  visited= {}
  visited[fs.lstatSync(rootdir).ino]= true
  cache[rootdir+'/']= superMeta  # this will be overridden if _default_meta found
  meta= loadDir(rootdir,superMeta,visited)
  preload(modules,meta,supersites)
  return meta

siteLookupRoot= null
sites= {}
sitesModuleSignature= /_sites$/
preload= (modules,superMeta,supersites)->
  for modname in modules
    itsMeta= meta_lookup(modname)
    m= require(modname)
    if m?.meta
      cache[modname]= extend(itsMeta,m.meta,modname)
    if sitesModuleSignature.test(modname)
      siteroot= path.dirname(modname)
      siteLookupRoot ?= siteroot
      sites[siteroot]= m
      (xsupersites= supersites.slice(0)).push(siteroot)
      for sitepath in m.paths
        loadTree(normalize(sitepath),superMeta,xsupersites)

module.exports=
  init: (baseSiteStack,options={})->
    dirs = baseSiteStack  # note: the stack is maintained in reverse order
    userPath= dirs[0]
    defaultPath= dirs[1]
    inter= loadTree(defaultPath,{},[])
    inter= extend(inter,options,'(options)')
    loadTree(userPath,inter,[defaultPath])
  meta_lookup: meta_lookup
  site_lookup: (req,res,next)->
    stack= []
    siteLookup= (sitename)=>
      lookup = sites[sitename]?.lookup
      if lookup?
        newname= lookup.call(this,req,res,next)
        if newname
          newname= normalize(newname)
          if newname == sitename
            return stack
          else
            stack.unshift(newname)
            siteLookup(newname)
      else
        return stack
    return if siteLookupRoot?
      siteLookup(siteLookupRoot)
    else
      stack
