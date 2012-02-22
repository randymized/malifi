module.exports= ()->
  @res.setHeader 'Content-Type','text/plain'
  @res.end(@meta.test_string)