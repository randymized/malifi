path= require 'path'
_= require 'underscore'

background= __dirname+'/../background'
example= __dirname+'/../example.com'
map=
  localhost: background
  '127.0.0.1': background
  'example.com': example
  'common.localhost': __dirname
prevSite= null;

exports= module.exports=
  lookup: ()->
      return map[@host.name]
  paths: _.uniq(_.values(map))
  wantsSiteStack: (siteStack)->
    prevSite= _.last(_.initial(siteStack))
  getPrevSite: ()->
    path.basename(prevSite)
