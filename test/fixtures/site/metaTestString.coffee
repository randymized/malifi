module.exports= ()->
  debugger
  @res.setHeader 'Content-Type','text/plain'
  @res.end(@meta.test_string)