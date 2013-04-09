module.exports= (req,res,next)->
  req.malifi.render('html',{sub: 'xyz'})
