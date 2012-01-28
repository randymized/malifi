extractHostFromHost= /([^:]+).*/
extractPortFromHost= /[^:]+:(.*)/

#Some utilities for working with the request object.  This is attached to the
#request object as req.malifi.utils

module.exports = exports= class RequestUtilities
  constructor: (@req)->
  hostname: -> @qhostname||= @req.headers.host.replace(extractHostFromHost,'$1')
  port: -> @qport||= @req.headers.host.replace(extractPortFromHost,'$1')

