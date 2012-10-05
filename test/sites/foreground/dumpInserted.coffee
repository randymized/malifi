module.exports= (req,res,next)->
  res.setHeader 'Content-Type','text/plain'
  res.end(req._inserted || '(null)')