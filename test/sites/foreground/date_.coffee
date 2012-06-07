module.exports= (req,res,next)->
  res.setHeader 'Content-Type','text/plain'
  args=req.args
  res.end("month:#{args[0]},day:#{args[1]},year:#{args[2]}")
