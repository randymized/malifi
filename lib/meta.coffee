connect = require('connect')
utilities= require('./utilities')
isModuleSync= utilities.isModuleSync

merged= (base,dominant)->
  return base unless dominant
  return dominant unless base
  r= {}
  r[key] = base[key] for key of base
  r[key] = dominant[key] for key of dominant
  return r


defaultMetaName= (dir)->
  "#{dir}/_default.meta"


load= (name,meta)->
  if isModuleSync(name)
    content = require(name)
    # A meta file module may be a function as well as an object.  If its a function,
    # it will be invoked with the parent metadata as an argument and should return
    # a metadata object.
    merged(meta, content?(meta) ? content)
  else
    meta

module.exports = class Meta
  constructor: (dirs,options={})->
    dirs = dirs.reverse()
    @base= require(defaultMetaName(dirs[0]))
    @optioned= merged(@base,options)
    @default= load(defaultMetaName(dirs[1]),@optioned)



