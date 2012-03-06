faviconFn = require('connect').favicon()
module.exports= (req,res,next)->
  faviconFn(req,res,next)