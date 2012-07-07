
extractHostAndPort= /([^:]+)(?::(.*))?/

exports = module.exports = class ParseHost
  constructor: (req)->
    matches = req.headers.host.match(extractHostAndPort);
    @name= matches[1]
    @port= matches[2]

exports.extractHostAndPort= extractHostAndPort