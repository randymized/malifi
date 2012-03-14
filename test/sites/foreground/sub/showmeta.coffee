module.exports= (req,res,next)->
  res.setHeader 'Content-Type','text/plain'
  res.end(req.malifi.meta.test_string)