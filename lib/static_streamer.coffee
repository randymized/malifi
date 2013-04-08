###
 * A large portion of the code in this file is adapted from:
 * Connect - staticProvider
 * Copyright(c) 2010 Sencha Inc.
 * Copyright(c) 2011 TJ Holowaychuk
 * MIT Licensed
 *
 * The overall file is
 * Copyright(c) 2012 Randy McLaughlin
 * MIT Licensed
 *
###

fs = require('fs')
connect = require('connect')
utils = connect.utils
mime = require('mime')
send = require('send')

exports= module.exports= staticHandler= (req,res,next,mimeWrapper)->
  res.socket= {} unless res.socket  # kludge related to the one on the next line.  res.socket is not otherwise set when processing a partial
  res.socket.parser= {incoming: req} unless res.socket.parser  #TODO: Send code says "wtf?" to getting req from res.socket.parser.incoming.  I echo the sentiment.  This is a kludge to make that kludge work if parser is not set (which in testing it is not)
  s=send(req,req.malifi.files[''])
  .maxage(req.malifi.meta.max_age_ || 0)
  .index(false)
  .on('error', next)
  .on('directory', next)
  .pipe(res)