_ = require('underscore')._
connect = require('connect')
path = require('path')
normalize = path.normalize
fs = require('fs')
existsSync = `(fs.existsSync) ? fs.existsSync : path.existsSync` # node 0.8 moved to fs
stripExtension= require('./strip_extension')
moduleExtensions= ['.js','.coffee','.json']

calc_site_key= (siteStack,reverse=false)->
  if reverse
    siteStack= siteStack.slice(0)
    siteStack= siteStack.reverse()
  siteStack.join(':')

# make sure the separators in a file name sort before any other chars
fileNameCompare= (a,b)->
  a= a.replace('/','\x01','g')
  b= b.replace('/','\x01','g')
  return (b < a) - (a < b)

isFileSync= (name)->
  existsSync(name) && fs.statSync(name).isFile()

# Would adding the proper extension to the given name find a file whose extension
# suggested that it could be a module?
isModuleSync= (name)->
  return true for ext in moduleExtensions when isFileSync(name+ext)
  false

metacache= {}

meta_lookup= (resourcePath,siteKey,setMetaPath)->
  mark= (meta,path)->
    meta.path_= path if setMetaPath
    return meta
  return mark({},'/') unless (from= metacache[siteKey])
  inner= (name)->
    if from[name]
      return mark(from[name],name)
    else
      name= path.normalize(name)    #remove any trailing slash
      lower= path.dirname(name)
      return mark(from['/'],'/') || {} if '.' == lower || '/' == lower
      return inner(lower+'/')
  return mark(c,resourcePath+'/') if c= from[resourcePath+'/']  # the original file name is that of a directory and it has default metadata
  inner(resourcePath)

siteLookupRoot= null
sites= {}
module.exports=
  init: (baseSiteStack,options={})->
    metafileSignature= /\.meta\.(js|coffee|json)$/
    moduleSignature= /\.(js|coffee|json)$/
    skipThisFileSignature= /^\.|^_default\.meta\.(js|coffee|json)$/
    stripDotMeta= /(.*?)(?:_default)?(?:\.meta)$/
    rawmetas= {}
    attribmetas= {}
    sitesModuleSignature= /_sites$/
    metatyper= /(^_default.meta$)|(?:(.*\/)_default.meta$)|(?:(.*)\.meta)/

    # Two-layer object clone.  A shallow copy of the original object is made, except that for any properties that
    # are an array or an object, the clone's property will be a shallow clone of the original's property.
    doubleclone= (orig)->
      r= {}
      for key,val of orig
        if val?
          if _.isFunction(val)
            r[key]=val
          else if _.isArray(val)
            r[key]=val.slice(0)
          else if _.isRegExp(val)
            r[key]=val
          else if _.isObject(val)
            r[key]=_.clone(val)
          else
            r[key]=val
        else
          delete r[key]
      return r

    extend= (base,dominant,name)->
      if base
        # A meta file module may be a function or an object.  If its a function,
        # it will be invoked with the parent metadata as an argument and should return
        # a metadata object.  The meta file can thus create metadata that is
        # affected by the values in the parent metadata
        dominant= dominant(doubleclone(base)) if typeof dominant == "function"
        r= _.clone(base)
        for key,val of dominant
          if val?
            r[key]=val
          else
            delete r[key]
      else
        r= _.clone(dominant)
      if r['build_lineage_']
        r['lineage_']= (base['lineage_']||[]).concat([name])
      r

    siteStacks= []
    loadTree= (siteStack) ->
      siteStacks.push(siteStack)
      rootdir= _.last(siteStack)
      myrawmetas= rawmetas[rootdir]= {}
      myattribmetas= attribmetas[rootdir]= {}
      modules= []
      loadDir= (dirname, visited) ->   #recursive
        fulldirname= path.join(rootdir,dirname)
        for filename in fs.readdirSync(fulldirname)
          partialname= path.join(dirname,filename)
          fullname= path.join(rootdir,partialname)
          stat = fs.lstatSync(path.join(fulldirname,filename))
          if stat.isDirectory()
            unless visited[stat.ino]  # do not follow circular symbolic link
              newvisited= {}
              newvisited[ino] = true for ino, val of visited
              newvisited[stat.ino]= true
              loadDir(partialname, newvisited)
          else
            if moduleSignature.test(filename)
              modname= stripExtension(partialname)
              m= require(fullname)
              metatype= modname.match(metatyper)
              if metatype
                if metatype[1]      # _default.meta           => /
                  myrawmetas['/']= m
                else if metatype[2] # something/_default.meta => /something/
                  myrawmetas['/'+metatype[2]]= m
                else                # anything[/]else.meta    => /anything[/]else
                  myrawmetas['/'+metatype[3]]= m
              else if m?.meta       # non-meta module that includes a meta attribute
                myattribmetas['/'+modname]= m.meta
              else if sitesModuleSignature.test(modname)
                siteroot= path.dirname(fullname)
                siteLookupRoot ?= siteroot
                sites[siteroot]= m
                for sitepath in m.paths
                  loadTree(siteStack.concat([normalize(sitepath)]))

      visited= {}
      visited[fs.lstatSync(rootdir).ino]= true
      loadDir('', visited)

    dirs = baseSiteStack  # note: the stack is maintained in reverse order
    userPath= dirs[0]
    defaultPath= dirs[1]
    loadTree([defaultPath])
    rawmetas[defaultPath]['/']= extend(rawmetas[defaultPath]['/'],options,'(options)')
    loadTree([defaultPath,userPath])

    for siteStack in siteStacks
      siteKey= calc_site_key(siteStack,true)
      metacache[siteKey]= {}
      rootdir= _.last(siteStack)
      meta= {}
      metanames= []
      for sitename in siteStack
        metanames= _.union(metanames,_.keys(rawmetas[sitename]),_.keys(attribmetas[sitename]))
      for metaname in _.uniq(metanames).sort(fileNameCompare)
        meta= meta_lookup(metaname,siteKey)
        for sitename in siteStack
          if rawmetas[sitename] && rawmetas[sitename][metaname]
            meta= extend(meta,rawmetas[sitename][metaname],path.join(sitename,metaname))
          if attribmetas[sitename] && attribmetas[sitename][metaname]
            meta= extend(meta,attribmetas[sitename][metaname],path.join(sitename,metaname+':'))
        metacache[siteKey][metaname]= meta

  meta_lookup: meta_lookup
  calc_site_key: calc_site_key

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
