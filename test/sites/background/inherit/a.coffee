module.exports= (req,res,next)->
  res.setHeader 'Content-Type','text/plain'
  meta= req._.meta
  res.end(JSON.stringify(meta))

module.exports.meta= (prev)->
  prev.test_string+= '+'
  prev