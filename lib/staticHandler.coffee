fs = require('fs')

exports= module.exports= staticHandler= (req,res,next)->
  fs.readFile req.malifi.path.full, (err,data)->
    if err
      return next()
    res.setHeader 'Content-Type', 'text/plain'
    res.end(data)
