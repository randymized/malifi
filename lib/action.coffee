_ = require('underscore')._
path = require('path')
join = path.join
utilities= require('./utilities')
forbidden = utilities.forbidden
select_actions= require('./select_actions')

exports = module.exports = action= (req,res,next)->
  malifi= req.malifi
  meta= malifi.meta
  pathobj= malifi.path
  meta._unhandled_handler?.log?(req)

  unless req.internal?  # internal requests and redirections may address resources that are hidden to the outside world
    if meta._forbiddenURLChars?.test(malifi.url.decoded_path)
      return forbidden(res)

    urlExtension = pathobj.extension
    if urlExtension && meta._allowed_url_extensions && '/' != urlExtension
      unless utilities.nameIsInArray(urlExtension,meta._allowed_url_extensions)
        return next()

  malifi.find_files pathobj.dirname, pathobj.basename, (files)->
    select_actions(req,res,next)
