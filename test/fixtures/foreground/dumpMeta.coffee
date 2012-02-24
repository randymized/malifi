module.exports= ()->
  @res.setHeader 'Content-Type','text/plain'
  @res.end(JSON.stringify(@meta))