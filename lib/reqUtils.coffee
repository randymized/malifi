extractHostFromHost= /([^:]+).*/
extractPortFromHost= /[^:]+:(.*)/

#Some utilities for working with the request object.  This is attached to the
#request object as req.malifi.utils

module.exports = exports= class RequestUtilities
  constructor: (@req)->
  hostname: () -> @hostname||= @req.headers.host.replace(extractHostFromHost,'$1')
  port: () -> @port||= @req.headers.host.replace(extractPortFromHost,'$1')

