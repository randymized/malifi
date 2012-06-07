module.exports= (req,res,next)->
  res.setHeader 'Content-Type','text/plain'
  res.end(req._.meta.path_)