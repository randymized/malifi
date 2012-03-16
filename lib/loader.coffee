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

extend= (base,dominant)->
  return dominant unless base
  r= _.clone(base)
  for key, value of dominant
    unless value?
      delete r[key] if _.has(r,key)
    else
      if key == '_actions'  #todo: allow similar "deeper copy" options for other keys (that, itself, could be in meta)
        r[key]= actionsCopier(dominant[key])
        oldactions= dominant[key]
        r[key].change= (cb)->
          dest= actionsCopier(oldactions)
          cb(dest)
          return dest
      else
        r[key] = value
  return r


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
    content = require(name)
    # A meta file module may be a function or an object.  If its a function,
    # it will be invoked with the parent metadata as an argument and should return
    # a metadata object.  The meta file can thus create metadata that is
    # affected by the values in the parent metadata
    content= content(superMeta) if typeof content == "function"
    extend(superMeta, content)

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
    require(modname) if meta_lookup(modname)?._preload_modules
    if sitesModuleSignature.test(modname)
      m = require(modname)  # assure load even if preload_modules is off
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
