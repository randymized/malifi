connect = require('connect')
path = require('path')
normalize = path.normalize
utilities= require('./utilities')
isModuleSync= utilities.isModuleSync
path = require('path')
normalize = path.normalize
fs = require('fs')
stripExtension= require('./strip_extension')
metafileSignature= /\.meta\.(js|coffee|json)$/
moduleSignature= /\.(js|coffee|json)$/
aDefaultFileSignature= /_default\.meta\.(js|coffee|json)$/
stripMetaExtension= /(.*)(?:\.meta\.(js|coffee|json))$/
canDescendNoMore= /^[/.]?\/$/

merged= (base,dominant)->
  return base unless dominant
  return dominant unless base
  r= {}
  r[key] = base[key] for key of base
  r[key] = dominant[key] for key of dominant
  return r


defaultMetaName= (dir)->
  "#{dir}/_default.meta"

cache= {}

find= (name)->
  if cache[name]
    return cache[name]
  else
    return {} if canDescendNoMore.test(name)  # emergency shut-off
    return find(path.dirname(name)+'/')

load= (name,superMeta,cachename)->
    content = require(name)
    # A meta file module may be a function or an object.  If its a function,
    # it will be invoked with the parent metadata as an argument and should return
    # a metadata object.  The meta file can thus create metadata that is
    # affected by the values in the parent metadata
    merged(superMeta, content?(superMeta) ? content)

loadTree= (dirname,superMeta) ->
  modules= []
  loadDir= (dirname,superMeta,visited) ->   #recursive
    defaultModName = path.join(dirname,'_default.meta')
    meta= if isModuleSync(defaultModName)
      cache[dirname+'/']= load(defaultModName,superMeta)
    else
      superMeta
    for filename in fs.readdirSync(dirname)
      unless aDefaultFileSignature.test(filename)
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
  visited[fs.lstatSync(dirname).ino]= true
  cache[dirname+'/']= superMeta  # this will be overridden if _default_meta found
  meta= loadDir(dirname,superMeta,visited)
  preload(modules,superMeta)
  return meta

siteLookupRoot= null
sites= {}
sitesModuleSignature= /_sites$/
preload= (modules,superMeta)->
  for modname in modules
    require(modname) if find(modname)?._preload_modules
    if sitesModuleSignature.test(modname)
      m = require(modname)  # assure load even if preload_modules is off
      sites[path.dirname(modname)]= m
      siteLookupRoot ?= path.dirname(modname)
      loadTree(normalize(sitepath),superMeta) for sitepath in m.paths

module.exports=
  init: (baseSiteStack,options={})->
    dirs = baseSiteStack  # note: the stack is maintained in reverse order
    userPath= dirs[0]
    defaultPath= dirs[1]
    inter= loadTree(defaultPath,{})
    inter= merged(inter,options)
    loadTree(userPath,inter)
  find: find
  site_lookup: (req)->
    stack= []
    siteLookup= (req,sitename)=>
      newname= sites[sitename]?.lookup?.call(this,req)
      if newname
        newname= normalize(newname)
        stack.unshift(newname)
        siteLookup(newname)
      else
        return stack
    return if siteLookupRoot?
      siteLookup(req,siteLookupRoot)
    else
      stack
