fs = require('fs')
connect = require('connect')

merged= (base,dominant)->
  return base unless dominant
  return dominant unless base
  r= Object.create(base)
  r[key] = dominant[key] for key in dominant
  return r


defaultMetaName= (dir)->
  "#{dir}/_default.meta"

isFile= (name)->
  try
    fs.statSync(name).isFile()
  catch e
    throw e unless e.code == 'ENOENT'
    false

load= (name,meta)->
  if isFile(name+'.js') || isFile(name+'.coffee')|| isFile(name+'.json')
    merged(meta,require(name))
  else
    meta

module.exports = class Meta
  constructor: (dirs,options={})->
    dirs = dirs.reverse()
    @base= require(defaultMetaName(dirs[0]))
    @optioned= merged(@base,options)
    @default= load(defaultMetaName(dirs[1]),@optioned)



