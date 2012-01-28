fs = require('fs')

exports= module.exports= (req,res,next)->
  debugger
  fs.readFile req.malifi.path.full, (err,data)->
    if err
      return next()
    res.setHeader 'Content-Type', 'text/plain'
    res.end(data)
