_ = require('underscore')._
connect = require('connect')
path = require('path')
normalize = path.normalize
path = require('path')
normalize = path.normalize
fs = require('fs')
stripExtension= require('./strip_extension')
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

metacache= {}

meta_lookup= (name,from)->
  from||= metacache
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

siteLookupRoot= null
sites= {}
module.exports=
  init: (baseSiteStack,options={})->
    metafileSignature= /\.meta\.(js|coffee|json)$/
    moduleSignature= /\.(js|coffee|json)$/
    skipThisFileSignature= /^\.|^_default\.meta\.(js|coffee|json)$/
    stripDotMeta= /(.*?)(?:_default)?(?:\.meta)$/
    rawmetas= {}
    sitesModuleSignature= /_sites$/

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
        (r['lineage_']= ((base['lineage_']||[])).slice(0)).push(name)
      r

    loadTree= (rootdir, supersites) ->
      myrawmetas= rawmetas[rootdir]= {}
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
              if metafileSignature.test(filename)
                myrawmetas[modname.replace(stripDotMeta,'$1')||'/']= m
              else if m?.meta
                myrawmetas[modname]= m.meta
              else if sitesModuleSignature.test(modname)
                siteroot= path.dirname(fullname)
                siteLookupRoot ?= siteroot
                sites[siteroot]= m
                (xsupersites= supersites.slice(0)).push(siteroot)
                for sitepath in m.paths
                  loadTree(normalize(sitepath), xsupersites)

      visited= {}
      visited[fs.lstatSync(rootdir).ino]= true
      loadDir('', visited)
      meta= {}
      supersites.push(rootdir)
      for sitename in supersites
        if rawmetas[sitename]
          meta= extend(meta,rawmetas[sitename]['/'],sitename+'/')
      metacache[rootdir+'/']= meta

      (metanames= _.keys(myrawmetas)).sort
      for metaname in metanames
        unless '/' == metaname
          fullmetaname= path.join(rootdir,metaname)
          metacache[fullmetaname]= extend(meta_lookup(fullmetaname),myrawmetas[metaname],fullmetaname)

    dirs = baseSiteStack  # note: the stack is maintained in reverse order
    userPath= dirs[0]
    defaultPath= dirs[1]
    loadTree(defaultPath, [])
    rawmetas[defaultPath]['/']= extend(rawmetas[defaultPath]['/'],options,'(options)')
    loadTree(userPath, [defaultPath])

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
