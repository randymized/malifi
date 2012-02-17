fs = require('fs')
path = require('path')
connect = require('connect')
utils = connect.utils
staticHandler= require('./static_handler')
utilities= require('./utilities')

exports = module.exports = class Action
  constructor: (@req,@res,@next)->
    debugger
    @malifi= @req.malifi

    # catch any use of .. to back out of the site's root directory:
    unless 0 == @malifi.path.full.indexOf(@malifi.pwd)
      return utils.forbidden(@res)

    # ignore non-GET requests?  TODO: check if handler exists for non-GET requests
    if @malifi.meta.getOnly? && 'GET' != @req.method && 'HEAD' != @req.method
      @next()

    #todo: presume index.html if */
    #todo: disallow outside access to _* and/or *_ files

    if '.txt' == @malifi.path.extension
      staticHandler(@req,@res,@next)
    else
      #for now, assume that if it's not txt, it's a module
      require(@malifi.path.full)(@req,@res,@next)
