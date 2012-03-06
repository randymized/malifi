module.exports= function(req,res,next) {
  res.setHeader('Content-Type','text/plain')
  res.end('Got JS')
}
