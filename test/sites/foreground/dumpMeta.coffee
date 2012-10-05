module.exports= (req,res,next)->
  res.setHeader 'Content-Type','application/json'
  res.end(JSON.stringify(req._.meta))