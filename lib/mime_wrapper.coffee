fs = require('fs')
mime = require('mime')

module.exports= mimeWrapper= (path,cb)->
  fs.stat path, (err, stat) =>
    if err
      cb(err)
    else
      cb(null,mime.lookup(path))
