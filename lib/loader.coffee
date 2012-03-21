_ = require('underscore')._
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
skipThisFileSignature= /^\.|^_default\.meta\.(js|coffee|json)$/
stripMetaExtension= /(.*)(?:\.meta\.(js|coffee|json))$/
canDescendNoMore= /^[/.]?\/$/

actionsCopier= (src)->
  dest= {}
  for key of src
    if typeof src[key] == 'object'
      if _.isArray(src[key])
        dest[key]= src[key][0...src[key].length]
      else
        dest[key]= actionsCopier(src[key])
    else
      dest[key]= src[key]
  return dest

metacloner= (from)->
  r= _.clone(from)
  r._actions= actionsCopier(r._actions)
  r

extend= (base,dominant)->
  return dominant unless base
  # A meta file module may be a function or an object.  If its a function,
  # it will be invoked with the parent metadata as an argument and should return
  # a metadata object.  The meta file can thus create metadata that is
  # affected by the values in the parent metadata
  dominant= dominant(metacloner(base)) if typeof dominant == "function"
  r= _.clone(base)
  for key,val of dominant
    if val?
      r[key]=val
    else
      delete r[key]
  r

cache= {}

meta_lookup= (name)->
  descend= (name)->
    if cache[name]
      return cache[name]
    else
      return {} if canDescendNoMore.test(name)  # emergency shut-off
      return meta_lookup(path.dirname(name)+'/')
  if c= cache[name+'/']  # the original file name is that of a directory and it has default metadata
    return c
  descend(name)

load= (name,superMeta,cachename)->
  extend(superMeta, require(name))

loadTree= (dirname,superMeta) ->
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
  visited[fs.lstatSync(dirname).ino]= true
  cache[dirname+'/']= superMeta  # this will be overridden if _default_meta found
  meta= loadDir(dirname,superMeta,visited)
  preload(modules,meta)
  return meta

siteLookupRoot= null
sites= {}
sitesModuleSignature= /_sites$/
preload= (modules,superMeta)->
  for modname in modules
    m= meta_lookup(modname)?._preload_modules && require(modname)
    if sitesModuleSignature.test(modname)
      m ?= require(modname)  # assure load even if preload_modules is off
      sites[path.dirname(modname)]= m
      siteLookupRoot ?= path.dirname(modname)
      for sitepath in m.paths
        loadTree(normalize(sitepath),superMeta)

module.exports=
  init: (baseSiteStack,options={})->
    dirs = baseSiteStack  # note: the stack is maintained in reverse order
    userPath= dirs[0]
    defaultPath= dirs[1]
    inter= loadTree(defaultPath,{})
    inter= extend(inter,options)
    loadTree(userPath,inter)
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
