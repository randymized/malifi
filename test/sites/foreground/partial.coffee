part= null
module.exports= (req,res,next)->
  res.setHeader 'Content-Type','text/plain'
  template= 'start...@...end'
  (part ?= req._.meta._partial('/hidden_.txt')) req,res,next,(buffer)->
    res.end(template.replace('@',buffer.toString()))
