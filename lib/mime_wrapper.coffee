fs = require('fs')
mime = require('mime')

module.exports= mimeWrapper= (path,cb)->
  fs.stat path, (err, stat) =>
    if err
      cb(err)
    else
      type = mime.lookup(path)
      cb(null,mime.lookup(path))
