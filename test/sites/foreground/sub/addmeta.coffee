module.exports= (req,res,next)->
  res.setHeader 'Content-Type','text/plain'
  res.end(req._.meta.test_string)

module.exports.meta= (prev)->
  prev.test_string+= '+'
  prev