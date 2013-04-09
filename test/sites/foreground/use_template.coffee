module.exports= (req,res,next)->
  req.malifi.render('text/html',{sub: 'xyz'})
