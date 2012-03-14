module.exports= (req,res,next)->
  res.setHeader 'Content-Type','text/plain'
  res.end(JSON.stringify(req._.meta))