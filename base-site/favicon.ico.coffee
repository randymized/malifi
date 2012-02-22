faviconFn = require('connect').favicon()
module.exports= ()->
  faviconFn(@req,@res,@next)