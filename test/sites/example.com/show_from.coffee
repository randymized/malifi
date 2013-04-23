module.exports= (req,res,next)->
  res.setHeader 'Content-Type','text/plain'
  res.end("Came from #{req.from_req.malifi.path.relative}")