connect = require('connect')
utilities= require('./utilities')
isFileSync= utilities.isFileSync

merged= (base,dominant)->
  return base unless dominant
  return dominant unless base
  r= Object.create(base)
  r[key] = dominant[key] for key in dominant
  return r


defaultMetaName= (dir)->
  "#{dir}/_default.meta"


load= (name,meta)->
  if isFileSync(name+'.js') || isFileSync(name+'.coffee')|| isFileSync(name+'.json')
    merged(meta,require(name))
  else
    meta

module.exports = class Meta
  constructor: (dirs,options={})->
    dirs = dirs.reverse()
    @base= require(defaultMetaName(dirs[0]))
    @optioned= merged(@base,options)
    @default= load(defaultMetaName(dirs[1]),@optioned)



