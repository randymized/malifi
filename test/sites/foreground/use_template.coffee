_= require 'underscore'

module.exports= (req,res,next)->
  req.malifi.render('text/html',{sub: 'xyz'})

module.exports.meta= (prev)->
  prev.cache_templates_= true
  prev