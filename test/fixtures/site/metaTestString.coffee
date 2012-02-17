module.exports= (req,res)->
  res.setHeader 'Content-Type','text/plain'
  res.end(req.malifi.meta.test_string)