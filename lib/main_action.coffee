utilities= require('./utilities')
forbidden = utilities.forbidden

exports = module.exports = action= ()->
  main_action= handler= (req,res,next)->
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

    malifi.next_middleware_layer= next
    malifi.find_files pathobj.dirname, pathobj.basename, (files)->
      if handler = meta._actions
        handler(req,res,next)
      else
        next()