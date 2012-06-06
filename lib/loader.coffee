_ = require('underscore')._
connect = require('connect')
path = require('path')
normalize = path.normalize
fs = require('fs')
stripExtension= require('./strip_extension')
moduleExtensions= ['.js','.coffee','.json']

calcSiteKey= (siteStack,reverse=false)->
  if reverse
    siteStack= siteStack.slice(0)
    siteStack= siteStack.reverse()
  siteStack.join('\1')

# make sure the separators in a file name sort before any other chars
fileNameCompare= (a,b)->
  a= a.replace('/','\1','g')
  b= b.replace('/','\1','g')
  return (b < a) - (a < b)

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

metacache= {}

meta_lookup= (name,from)->
  from||= metacache
  descend= (name)->
    if from[name]
      return from[name]
    else
      name= path.normalize(name)    #remove any trailing slash
      lower= path.dirname(name)
      return {} if lower == name  # emergency shut-off: already at root directory
      return meta_lookup(lower+'/')
  if c= from[name+'/']  # the original file name is that of a directory and it has default metadata
    return c
  descend(name)

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

    extend= (base,dominant,name)->
      if base
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
                else if metatype[2] # something/_default.meta => something/
                  myrawmetas[metatype[2]]= m
                else                # anything[/]else.meta    => anything[/]else
                  myrawmetas[metatype[3]]= m
              else if m?.meta       # non-meta module that includes a meta attribute
                myattribmetas[modname]= m.meta
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
      rootdir= _.last(siteStack)
      sitekey= calcSiteKey(siteStack,true)
      meta= {}
      metanames= []
      for sitename in siteStack
        metanames= _.union(metanames,_.keys(rawmetas[sitename]),_.keys(attribmetas[sitename]))
      for metaname in _.uniq(metanames).sort(fileNameCompare)
        fullmetaname= path.join(rootdir,metaname)
        meta= meta_lookup(fullmetaname)
        for sitename in siteStack
          if rawmetas[sitename] && rawmetas[sitename][metaname]
            meta= extend(meta,rawmetas[sitename][metaname],path.join(sitename,metaname))
          if attribmetas[sitename] && attribmetas[sitename][metaname]
            meta= extend(meta,attribmetas[sitename][metaname],path.join(sitename,metaname+':'))
        metacache[fullmetaname]= meta

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
